/// Whether the recipe line [text] does not count in the nutrition, so a
/// cooking starts with it left out: its measure is a pinch ("1 Prise Salz",
/// "Msp. Muskat", "a pinch of nutmeg"), or it names only salt, pepper or
/// water ("Salz", "500 ml Wasser", "Pfeffer aus der Mühle", "Salz nach
/// Geschmack", "1/2 TL Schwarzer Pfeffer", whose kind may start with a
/// capital). "etwas" and "nach Geschmack" alone say nothing: "etwas Öl"
/// and "Zucker nach Geschmack" carry kcal and are asked like any other line.
/// A recipe's own mark comes first; this is the rule without one.
bool cookLineNotCounted(String text) {
  final trimmed = text.trim();
  if (_pinch.hasMatch(trimmed)) return true;
  final words = [
    for (final match in _word.allMatches(trimmed))
      if (!_notFood.contains(match[0]!.toLowerCase())) match[0]!,
  ];
  if (words.isEmpty) return false;
  // German names a food with a capital; adjectives such as "gemahlener" stay
  // small and say nothing about what the food is, unless they start the food's
  // name ("Schwarzer Pfeffer").
  final nouns = [
    for (final word in words)
      if (word[0] != word[0].toLowerCase()) word.toLowerCase(),
  ];
  return nouns.isEmpty
      ? words.every((word) => _plainWords.contains(word.toLowerCase()))
      : nouns.any(_uncounted.contains) &&
            nouns.every(
              (noun) => _uncounted.contains(noun) || _kinds.contains(noun),
            );
}

const _uncounted = {
  'salz',
  'meersalz',
  'pfeffer',
  'wasser',
  'salt',
  'pepper',
  'water',
};

// What a line may say of the kind of salt, pepper or water.
const _kinds = {
  'schwarzer',
  'weißer',
  'weisser',
  'bunter',
  'grüner',
  'roter',
  'grobes',
  'grober',
  'feines',
  'feiner',
  'frisch',
  'frischer',
  'frisches',
  'gemahlener',
  'kaltes',
  'warmes',
  'heißes',
  'lauwarmes',
  'sea',
  'black',
  'white',
  'fresh',
  'freshly',
  'ground',
  'cold',
  'warm',
};

// What a line in small letters may say besides salt, pepper or water.
const Set<String> _plainWords = {
  ..._uncounted,
  ..._kinds,
  'und',
  'oder',
  'and',
  'or',
};

// Measures and words around a food that name none.
const _notFood = {
  'etwas',
  'nach',
  'geschmack',
  'some',
  'to',
  'taste',
  'g',
  'kg',
  'ml',
  'l',
  'el',
  'tl',
  'esslöffel',
  'teelöffel',
  'tasse',
  'tassen',
  'liter',
  'mühle',
  'kochen',
  'tbsp',
  'tsp',
  'cup',
  'cups',
};

final _pinch = RegExp(
  r'^(?:[\d¼½¾⅓⅔⅛][\d¼½¾⅓⅔⅛.,/\s]*|ein(?:e|en|er)?\s+|an?\s+)?'
  r'(?:prisen?|msp\.?|messerspitzen?|pinch(?:es)?)'
  '(?![a-zA-ZäöüÄÖÜß])',
  caseSensitive: false,
);
final _word = RegExp('[a-zA-ZäöüÄÖÜß]+');
