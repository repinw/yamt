/// The foods of [foods] that the food words [words] of a recipe step name.
/// A word names the foods that have it as a word, else those that have it
/// as a plural ("egg", "eggs"), else those that it names with a part of the
/// food after it ("knoblauchzehe" for "knoblauch"). So "Tomatenmark" never
/// names "Tomaten", and "creamy" not "cream".
List<String> foodsNamedBy(
  Set<String> words,
  List<({String label, Set<String> words})> foods,
) {
  final named = <String>{};
  for (final word in words) {
    // The closest form wins.
    for (final same in [
      (String name) => name == word,
      (String name) => _pluralForm(name, word),
      (String name) => _partOf(name, word) || _partOf(word, name),
    ]) {
      final found = [
        for (final food in foods)
          if (food.words.any(same)) food.label,
      ];
      if (found.isNotEmpty) {
        named.addAll(found);
        break;
      }
    }
  }
  return [
    for (final food in foods)
      if (named.contains(food.label)) food.label,
  ];
}

bool _pluralForm(String a, String b) {
  final (short, long) = a.length <= b.length ? (a, b) : (b, a);
  // The matcher keeps "-e" of "tomatoes" ("tomatoe") and short plurals.
  return short.length >= 3 &&
      const ['e', 's', 'es', 'n', 'en'].any((end) => long == '$short$end');
}

// Parts of a food that recipes join to its name, singular as the matcher
// keeps them. shortcut: a fixed list instead of a compound dictionary; add a
// part when a recipe misses one.
const _parts = {
  'blatt',
  'blätter',
  'knolle',
  'scheibe',
  'stange',
  'stück',
  'stücke',
  'würfel',
  'zehe',
};

/// Whether [word] is [food] with a part after it, such as "knoblauchzehe".
bool _partOf(String food, String word) =>
    food.length >= 3 &&
    word.startsWith(food) &&
    _parts.contains(word.substring(food.length));
