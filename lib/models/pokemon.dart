class PokemonEntry {
  const PokemonEntry({required this.id, required this.name});
  final int id;
  final String name;
  String get displayName => prettyName(name);
  String get number => '#${id.toString().padLeft(3, '0')}';
  factory PokemonEntry.fromJson(Map<String, dynamic> json) => PokemonEntry(
    id: int.parse(
      Uri.parse(
        json['url'] as String,
      ).pathSegments.where((s) => s.isNotEmpty).last,
    ),
    name: json['name'] as String,
  );
}

class Pokemon {
  const Pokemon({
    required this.id,
    required this.name,
    required this.types,
    required this.image,
    required this.shinyImage,
    required this.height,
    required this.weight,
    required this.abilities,
    required this.stats,
    required this.speciesUrl,
    this.thumbnail,
  });
  final int id;
  final String name;
  final List<String> types;
  final String? image;
  final String? shinyImage;
  final String? thumbnail;
  final double height;
  final double weight;
  final List<String> abilities;
  final Map<String, int> stats;
  final String speciesUrl;
  String get displayName => prettyName(name);
  String get number => '#${id.toString().padLeft(3, '0')}';
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final sprites = json['sprites'] as Map<String, dynamic>;
    final artwork =
        (sprites['other'] as Map<String, dynamic>?)?['official-artwork']
            as Map<String, dynamic>?;
    return Pokemon(
      id: json['id'] as int,
      name: json['name'] as String,
      types: (json['types'] as List)
          .map((t) => t['type']['name'] as String)
          .toList(),
      image:
          artwork?['front_default'] as String? ??
          sprites['front_default'] as String?,
      shinyImage:
          artwork?['front_shiny'] as String? ??
          sprites['front_shiny'] as String?,
      thumbnail: sprites['front_default'] as String?,
      height: (json['height'] as num) / 10,
      weight: (json['weight'] as num) / 10,
      abilities: (json['abilities'] as List)
          .map((a) => a['ability']['name'] as String)
          .toList(),
      stats: {
        for (final stat in json['stats'] as List)
          stat['stat']['name'] as String: stat['base_stat'] as int,
      },
      speciesUrl: json['species']['url'] as String,
    );
  }

  factory Pokemon.fromCompact(List<dynamic> row, {String? thumbnail}) {
    final id = row[0] as int;
    const sprites =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon';
    const statNames = [
      'hp',
      'attack',
      'defense',
      'special-attack',
      'special-defense',
      'speed',
    ];
    final values = (row[5] as List).cast<int>();
    return Pokemon(
      id: id,
      name: row[1] as String,
      types: (row[2] as List).cast<String>(),
      image: '$sprites/other/official-artwork/$id.png',
      shinyImage: '$sprites/other/official-artwork/shiny/$id.png',
      thumbnail: thumbnail ?? '$sprites/$id.png',
      height: (row[3] as num) / 10,
      weight: (row[4] as num) / 10,
      stats: {
        for (var i = 0; i < statNames.length; i++) statNames[i]: values[i],
      },
      abilities: (row[6] as List).cast<String>(),
      speciesUrl: 'https://pokeapi.co/api/v2/pokemon-species/${row[7]}/',
    );
  }
}

String prettyName(String name) => name
    .split('-')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');

const generationNames = [
  'Todas las generaciones',
  'Kanto · Gen. I',
  'Johto · Gen. II',
  'Hoenn · Gen. III',
  'Sinnoh · Gen. IV',
  'Teselia · Gen. V',
  'Kalos · Gen. VI',
  'Alola · Gen. VII',
  'Galar · Gen. VIII',
  'Paldea · Gen. IX',
];
const generationEnds = [0, 151, 251, 386, 493, 649, 721, 809, 905, 1025];
int generationFor(int id) {
  for (var i = 1; i < generationEnds.length; i++) {
    if (id <= generationEnds[i]) return i;
  }
  return 0;
}
