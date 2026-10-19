import '../models/pokemon.dart';

class SearchResult {
  const SearchResult(this.entries, {this.correction});
  final List<PokemonEntry> entries;
  final String? correction;
}

/// Matches the complete API index locally, including adjacent transpositions.
class PokemonSearch {
  static String normalize(String value) {
    var text = value.trim().toLowerCase();
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
      '♀': 'f',
      '♂': 'm',
    };
    accents.forEach(
      (key, replacement) => text = text.replaceAll(key, replacement),
    );
    return text.replaceAll(RegExp('[^a-z0-9]'), '');
  }

  static SearchResult find(String query, List<PokemonEntry> index) {
    final term = normalize(query);
    if (term.isEmpty) return SearchResult(index);
    final id = int.tryParse(term);
    if (id != null) {
      return SearchResult(index.where((p) => p.id == id).toList());
    }
    final exact = index.where((p) => normalize(p.name) == term).toList();
    if (exact.isNotEmpty) return SearchResult(exact);
    final partial =
        index.where((p) => normalize(p.name).contains(term)).toList()..sort((
          a,
          b,
        ) {
          final aPrefix = normalize(a.name).startsWith(term);
          final bPrefix = normalize(b.name).startsWith(term);
          return aPrefix == bPrefix ? a.id.compareTo(b.id) : (aPrefix ? -1 : 1);
        });
    if (partial.isNotEmpty) return SearchResult(partial);
    if (term.length < 3) return const SearchResult([]);
    final maxDistance = term.length <= 4 ? 1 : (term.length <= 8 ? 2 : 3);
    final scored = <({PokemonEntry entry, int distance, double similarity})>[];
    for (final entry in index) {
      final candidate = normalize(entry.name);
      if ((candidate.length - term.length).abs() > maxDistance) continue;
      final distance = _distance(term, candidate);
      final similarity =
          1 -
          distance /
              (candidate.length > term.length ? candidate.length : term.length);
      if (distance <= maxDistance && similarity >= 0.55) {
        scored.add((entry: entry, distance: distance, similarity: similarity));
      }
    }
    scored.sort((a, b) {
      final byDistance = a.distance.compareTo(b.distance);
      if (byDistance != 0) return byDistance;
      final bySimilarity = b.similarity.compareTo(a.similarity);
      return bySimilarity != 0
          ? bySimilarity
          : a.entry.id.compareTo(b.entry.id);
    });
    if (scored.isEmpty) return const SearchResult([]);
    return SearchResult(
      scored.take(8).map((s) => s.entry).toList(),
      correction: scored.first.entry.displayName,
    );
  }

  static int _distance(String a, String b) {
    final rows = List.generate(
      a.length + 1,
      (_) => List.filled(b.length + 1, 0),
    );
    for (var i = 0; i <= a.length; i++) {
      rows[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      rows[0][j] = j;
    }
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final candidates = [
          rows[i - 1][j] + 1,
          rows[i][j - 1] + 1,
          rows[i - 1][j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1),
        ];
        if (i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]) {
          candidates.add(rows[i - 2][j - 2] + 1);
        }
        rows[i][j] = candidates.reduce((x, y) => x < y ? x : y);
      }
    }
    return rows[a.length][b.length];
  }
}
