import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

class PokeApiException implements Exception {
  const PokeApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PokemonRepository {
  PokemonRepository({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  final _pokemon = <int, Future<Pokemon>>{};
  final _types = <String, Future<Set<int>>>{};
  final _descriptions = <String, Future<String>>{};
  static const _base = 'https://pokeapi.co/api/v2';

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
    final data = await _get('$_base/pokemon?limit=20000');
    // Alternate forms are excluded from the national Pokédex and generations.
    return (data['results'] as List)
        .map((p) => PokemonEntry.fromJson(p as Map<String, dynamic>))
        .where((p) => p.id <= 1025)
        .toList();
  }

  Future<Pokemon> fetchPokemon(int id) => _pokemon.putIfAbsent(id, () async {
    try {
      return Pokemon.fromJson(await _get('$_base/pokemon/$id'));
    } catch (_) {
      _pokemon.remove(id);
      rethrow;
    }
  });

  Future<Set<int>> fetchType(String type) => _types.putIfAbsent(type, () async {
    try {
      final data = await _get('$_base/type/$type');
      return (data['pokemon'] as List)
          .map(
            (p) =>
                PokemonEntry.fromJson(p['pokemon'] as Map<String, dynamic>).id,
          )
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
