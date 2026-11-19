import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

class PokeApiException implements Exception {
  const PokeApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PokemonRepository {
  PokemonRepository({
    http.Client? client,
    Future<String> Function()? catalogLoader,
  }) : _client = client ?? http.Client(),
       _catalogLoader =
           catalogLoader ??
           (() => rootBundle.loadString('assets/data/catalog.json'));
  final http.Client _client;
  final Future<String> Function() _catalogLoader;
  Future<Map<int, Pokemon>>? _catalog;
  final _types = <String, Future<Set<int>>>{};
  final _descriptions = <String, Future<String>>{};

  Future<Map<int, Pokemon>> _loadCatalog() => _catalog ??= () async {
    try {
      final data = jsonDecode(await _catalogLoader()) as Map<String, dynamic>;
      if (data['version'] != 1) {
        throw const FormatException('Unsupported catalog');
      }
      return {
        for (final row in data['rows'] as List)
          row[0] as int: Pokemon.fromCompact(
            row as List<dynamic>,
            thumbnail: kIsWeb
                ? Uri.base.resolve('lite/sprites/${row[0]}.png').toString()
                : null,
          ),
      };
    } catch (_) {
      _catalog = null;
      throw const PokeApiException(
        'No pudimos abrir el catálogo. Vuelve a cargar la Pokédex.',
      );
    }
  }();

  Future<Map<String, dynamic>> _get(String url) async {
    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 18));
      if (response.statusCode != 200) {
        throw const PokeApiException(
          'PokéAPI no está disponible en este momento. Intenta de nuevo.',
        );
      }
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } on PokeApiException {
      rethrow;
    } catch (_) {
      throw const PokeApiException(
        'No pudimos conectar con PokéAPI. Revisa tu conexión y vuelve a intentarlo.',
      );
    }
  }

  Future<List<PokemonEntry>> fetchIndex() async {
    final catalog = await _loadCatalog();
    return catalog.values
        .map((p) => PokemonEntry(id: p.id, name: p.name))
        .toList();
  }

  Future<Pokemon> fetchPokemon(int id) async {
    final pokemon = (await _loadCatalog())[id];
    if (pokemon == null) {
      throw const PokeApiException('Este Pokémon no está en el catálogo.');
    }
    return pokemon;
  }

  Future<Set<int>> fetchType(String type) => _types.putIfAbsent(type, () async {
    try {
      final catalog = await _loadCatalog();
      return catalog.values
          .where((p) => p.types.contains(type))
          .map((p) => p.id)
          .toSet();
    } catch (_) {
      _types.remove(type);
      rethrow;
    }
  });

  Future<String> fetchDescription(
    String speciesUrl,
  ) => _descriptions.putIfAbsent(speciesUrl, () async {
    try {
      final data = await _get(speciesUrl);
      final entries = (data['flavor_text_entries'] as List).where(
        (e) => e['language']['name'] == 'es',
      );
      if (entries.isEmpty) {
        return 'Todavía no hay una descripción en español para este Pokémon.';
      }
      return (entries.last['flavor_text'] as String).replaceAll(
        RegExp(r'[\n\r\f]+'),
        ' ',
      );
    } catch (_) {
      _descriptions.remove(speciesUrl);
      rethrow;
    }
  });

  void dispose() => _client.close();
}
