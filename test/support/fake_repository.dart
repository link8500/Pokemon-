import 'package:pokemon/models/pokemon.dart';
import 'package:pokemon/services/pokemon_repository.dart';

class FakeRepository extends PokemonRepository {
  bool fail = false;
  final entries = const [
    PokemonEntry(id: 1, name: 'bulbasaur'),
    PokemonEntry(id: 25, name: 'pikachu'),
    PokemonEntry(id: 132, name: 'ditto'),
    PokemonEntry(id: 172, name: 'pichu'),
  ];
  @override
  Future<List<PokemonEntry>> fetchIndex() async {
    if (fail) throw const PokeApiException('No pudimos conectar con PokéAPI.');
    return entries;
  }

  @override
  Future<Pokemon> fetchPokemon(int id) async {
    if (fail) throw const PokeApiException('No pudimos conectar con PokéAPI.');
    return Pokemon(
      id: id,
      name: entries.firstWhere((p) => p.id == id).name,
      types: [
        id == 132
            ? 'normal'
            : id == 1
            ? 'grass'
            : 'electric',
      ],
      image: null,
      shinyImage: null,
      height: 0.3,
      weight: 4,
      abilities: ['limber'],
      stats: {'hp': 48, 'attack': 48, 'defense': 48, 'speed': 48},
      speciesUrl: 'https://pokeapi.co/api/v2/pokemon-species/$id',
    );
  }

  @override
  Future<Set<int>> fetchType(String type) async => switch (type) {
    'normal' => {132},
    'grass' => {1},
    'electric' => {25, 172},
    _ => {},
  };
  @override
  Future<String> fetchDescription(String speciesUrl) async =>
      'Un Pokémon de prueba.';
}
