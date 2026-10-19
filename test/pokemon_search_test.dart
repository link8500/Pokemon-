import 'package:flutter_test/flutter_test.dart';
import 'package:pokemon/models/pokemon.dart';
import 'package:pokemon/services/pokemon_search.dart';

const entries = [
  PokemonEntry(id: 1, name: 'bulbasaur'),
  PokemonEntry(id: 4, name: 'charmander'),
  PokemonEntry(id: 25, name: 'pikachu'),
  PokemonEntry(id: 29, name: 'nidoran-f'),
  PokemonEntry(id: 122, name: 'mr-mime'),
  PokemonEntry(id: 132, name: 'ditto'),
  PokemonEntry(id: 172, name: 'pichu'),
];

void main() {
  test('dito finds Ditto and explains the correction', () {
    final result = PokemonSearch.find('dito', entries);
    expect(result.entries.first.name, 'ditto');
    expect(result.correction, 'Ditto');
  });
  test('a missing letter ranks Pikachu ahead of Pichu', () {
    expect(PokemonSearch.find('pikchu', entries).entries.first.name, 'pikachu');
  });
  test('adjacent swapped letters are corrected', () {
    expect(PokemonSearch.find('ditot', entries).entries.first.name, 'ditto');
  });
  test('exact names do not trigger a correction', () {
    final result = PokemonSearch.find('DITTO', entries);
    expect(result.entries.single.id, 132);
    expect(result.correction, isNull);
  });
  test('accents, spaces, punctuation and gender symbols are normalized', () {
    expect(PokemonSearch.find('  Píká chú ', entries).entries.single.id, 25);
    expect(PokemonSearch.find('Mr. Mime', entries).entries.single.id, 122);
    expect(PokemonSearch.find('Nidoran ♀', entries).entries.single.id, 29);
  });
  test('numbers accept hashes and leading zeros', () {
    expect(PokemonSearch.find('#0025', entries).entries.single.id, 25);
    expect(PokemonSearch.find('132', entries).entries.single.name, 'ditto');
  });
  test('partial names match without claiming a typo', () {
    final result = PokemonSearch.find('char', entries);
    expect(result.entries.single.name, 'charmander');
    expect(result.correction, isNull);
  });
  test('unrelated terms and unknown numbers have no false matches', () {
    expect(PokemonSearch.find('zzzzzzzz', entries).entries, isEmpty);
    expect(PokemonSearch.find('9999', entries).entries, isEmpty);
  });
  test('empty search returns the catalog', () {
    expect(PokemonSearch.find('   ', entries).entries, entries);
  });
}
