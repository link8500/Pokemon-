import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pokemon.dart';
import '../services/pokemon_repository.dart';
import '../services/pokemon_search.dart';

enum PokemonSort { number, numberDescending, name, nameDescending }

class PokedexController extends ChangeNotifier {
  PokedexController({PokemonRepository? repository})
    : repository = repository ?? PokemonRepository();
  final PokemonRepository repository;
  List<PokemonEntry> index = [];
  List<PokemonEntry> matches = [];
  List<Pokemon> visible = [];
  final Set<int> favorites = {};
  SharedPreferences? _preferences;
  String query = '';
  String? selectedType;
  int generation = 0;
  PokemonSort sort = PokemonSort.number;
  bool favoritesOnly = false;
  bool loading = true;
  String? error;
  String? correction;
  int page = 0;
  static const pageSize = 12;
  int _request = 0;
  bool _disposed = false;
  Timer? _debounce;
  int get pages => (matches.length / pageSize).ceil();
  int get total => index.length;

  Future<void> initialize() async {
    loading = true;
    error = null;
    _emit();
    try {
      final results = await Future.wait([
        repository.fetchIndex(),
        _loadFavorites(),
      ]);
      if (_disposed) return;
      index = results.first as List<PokemonEntry>;
      await refresh();
    } catch (e) {
      if (_disposed) return;
      error = e.toString();
      loading = false;
      _emit();
    }
  }

  Future<void> _loadFavorites() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      favorites.addAll(
        (_preferences!.getStringList('pokedex.favorites') ?? [])
            .map(int.tryParse)
            .whereType<int>(),
      );
    } catch (_) {
      /* Browsers without storage keep favorites for this session. */
    }
  }

  void search(String value, {bool immediately = false}) {
    query = value;
    _debounce?.cancel();
    _request++;
    if (immediately) {
      unawaited(refresh());
    } else {
      _debounce = Timer(const Duration(milliseconds: 280), refresh);
    }
  }

  Future<void> setType(String? type) async {
    selectedType = type;
    await refresh();
  }

  Future<void> setGeneration(int value) async {
    generation = value;
    await refresh();
  }

  Future<void> setSort(PokemonSort value) async {
    sort = value;
    await refresh();
  }

  Future<void> showFavorites(bool value) async {
    favoritesOnly = value;
    await refresh();
  }

  Future<void> toggleFavorite(int id) async {
    if (!favorites.add(id)) favorites.remove(id);
    _emit();
    try {
      await _preferences?.setStringList(
        'pokedex.favorites',
        favorites.map((id) => '$id').toList(),
      );
    } catch (_) {
      /* Favorites remain available for this session. */
    }
    if (favoritesOnly && !_disposed) await refresh(resetPage: false);
  }

  Future<void> reset() async {
    _debounce?.cancel();
    query = '';
    selectedType = null;
    generation = 0;
    sort = PokemonSort.number;
    await refresh();
  }

  Future<void> setPage(int value) async {
    if (value < 0 || value >= pages) return;
    page = value;
    await refresh(resetPage: false);
  }

  Future<void> refresh({bool resetPage = true}) async {
    _debounce?.cancel();
    final request = ++_request;
    if (resetPage) page = 0;
    loading = true;
    error = null;
    _emit();
    try {
      final result = PokemonSearch.find(query, index);
      var filtered = result.entries;
      if (generation > 0) {
        filtered = filtered
            .where((p) => generationFor(p.id) == generation)
            .toList();
      }
      if (favoritesOnly) {
        filtered = filtered.where((p) => favorites.contains(p.id)).toList();
      }
      if (selectedType != null) {
        final ids = await repository.fetchType(selectedType!);
        if (_disposed || request != _request) return;
        filtered = filtered.where((p) => ids.contains(p.id)).toList();
      }
      filtered = [...filtered];
      if (result.correction == null || sort != PokemonSort.number) {
        filtered.sort(
          (a, b) => switch (sort) {
            PokemonSort.number => a.id.compareTo(b.id),
            PokemonSort.numberDescending => b.id.compareTo(a.id),
            PokemonSort.name => a.name.compareTo(b.name),
            PokemonSort.nameDescending => b.name.compareTo(a.name),
          },
        );
      }
      final lastPage = filtered.isEmpty
          ? 0
          : ((filtered.length - 1) ~/ pageSize);
      final targetPage = page > lastPage ? lastPage : page;
      final pokemon = await Future.wait(
        filtered
            .skip(targetPage * pageSize)
            .take(pageSize)
            .map((p) => repository.fetchPokemon(p.id)),
      );
      if (_disposed || request != _request) return;
      matches = filtered;
      correction = result.correction;
      visible = pokemon;
      page = targetPage;
      loading = false;
      _emit();
    } catch (e) {
      if (_disposed || request != _request) return;
      error = e.toString();
      loading = false;
      _emit();
    }
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    repository.dispose();
    super.dispose();
  }
}
