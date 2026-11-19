import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokemon/services/pokemon_repository.dart';

void main() {
  test(
    'El catálogo completo, tipos y fichas no hacen peticiones HTTP',
    () async {
      var reads = 0;
      final repository = PokemonRepository(
        catalogLoader: () async {
          reads++;
          return File('assets/data/catalog.json').readAsString();
        },
        client: MockClient(
          (request) async => fail('Petición inesperada: ${request.url}'),
        ),
      );
      addTearDown(repository.dispose);
      final index = await repository.fetchIndex();
      expect(index.length, 1025);
      expect(index.first.id, 1);
      expect(index.last.id, 1025);
      final ditto = await repository.fetchPokemon(132);
      expect(ditto.name, 'ditto');
      expect(ditto.height, 0.3);
      expect(ditto.weight, 4);
      expect(ditto.stats.values, everyElement(48));
      expect(ditto.abilities, containsAll(['limber', 'imposter']));
      expect(ditto.thumbnail, endsWith('/132.png'));
      expect(ditto.image, contains('/official-artwork/132.png'));
      expect(ditto.speciesUrl, endsWith('/132/'));
      expect(await repository.fetchType('normal'), contains(132));
      expect(await repository.fetchType('electric'), contains(25));
      expect(await repository.fetchType('invalid'), isEmpty);
      expect(reads, 1);
      await expectLater(
        repository.fetchPokemon(99999),
        throwsA(isA<PokeApiException>()),
      );
    },
  );

  test('Las descripciones se solicitan una vez y se reutilizan', () async {
    var requests = 0;
    final repository = PokemonRepository(
      client: MockClient((request) async {
        requests++;
        return http.Response(
          '{"flavor_text_entries":[{"language":{"name":"es"},"flavor_text":"Un Pokémon\\ncurioso."}]}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(repository.dispose);
    const url = 'https://pokeapi.co/api/v2/pokemon-species/132/';
    expect(await repository.fetchDescription(url), 'Un Pokémon curioso.');
    expect(await repository.fetchDescription(url), 'Un Pokémon curioso.');
    expect(requests, 1);
  });

  test('Un catálogo que falla puede volver a cargarse', () async {
    var reads = 0;
    final repository = PokemonRepository(
      catalogLoader: () async {
        if (++reads == 1) throw const FileSystemException('No disponible');
        return File('assets/data/catalog.json').readAsString();
      },
    );
    addTearDown(repository.dispose);
    await expectLater(
      repository.fetchIndex(),
      throwsA(isA<PokeApiException>()),
    );
    expect((await repository.fetchIndex()).length, 1025);
    expect(reads, 2);
  });
}
