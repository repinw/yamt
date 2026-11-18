import 'package:collection/collection.dart';
import 'package:yamt/features/inventory/domain/ingredient_compound_head.dart';
import 'package:yamt/features/inventory/domain/ingredient_match_lexicon.dart';
import 'package:yamt/features/inventory/domain/ingredient_match_tokens.dart';

/// The words of [text] that can name a food, as written and in their order: no
/// amount, no unit, no word such as "Bio". A hyphen joins a compound and an
/// accent goes ("Crème" is "Creme"), or the word would fall apart at it.
List<String> cookFoodWords(String text) => [
  for (final word in normalizeIngredientMatchText(
    _withoutAccents(text.toLowerCase()).replaceAll('-', ''),
  ).split(' '))
    if (ingredientMatchTokens(word, fallbackIngredientMatchLexicon).isNotEmpty)
      word,
];

/// Whether [name] really is the food [said], whose last word names it ("rote
/// Zwiebel"): a food word of [name] is that word or ends with it, the head of
/// a compound, in the singular or plural, which may take an umlaut ("Äpfel").
/// "Öl" is "Rapsöl", and by chance "Lauch" is "Knoblauch", but "Wein" is no
/// "Schweinefilet", "Ei" no "Basmatireis" and "Reis" no "Reiswaffeln". A short
/// everyday name is the food named the long way, either way round, when what
/// follows it is a part of the same food ("Hack" and "Rinderhackfleisch",
/// "Hähnchen" and "Hähnchenbrust") or, at the start of the word, names an
/// amount of it, which the shared rule knows ("Knoblauch" and
/// "Knoblauchzehen").
bool cookNameIsFood(String name, String said) {
  final head = cookFoodWords(said).lastOrNull;
  if (head == null) return false;
  final saidForms = _saidForms(head);
  // Not of two letters, or "Öl" would be the end of "Alkohol".
  final plainForms = {
    for (final form in saidForms)
      if (form.length > 2) _withoutUmlauts(form),
  };
  return cookFoodWords(name).any((word) {
    final forms = _forms(word);
    if (_holdsByChance(word, saidForms) || _holdsByChance(head, forms)) {
      return false;
    }
    return _endsWithFood(word, saidForms) ||
        _endsWithFood(_withoutUmlauts(word), plainForms) ||
        forms.any(saidForms.contains) ||
        _isLongNameOf(word, saidForms) ||
        _isLongNameOf(head, forms);
  });
}

/// Whether a food word of [text] sits only inside a word of [name], such as
/// "Ei" in "Reis", "Öl" in "Kölln" or "Wein" in "Schweinefilet". `false` when
/// it starts or ends a word, when a part of the same food follows it, and when
/// the words of [name] do not hold it.
bool cookFoodOnlyInsideWord(String text, String name) {
  final words = cookFoodWords(name);
  var inside = false;
  for (final food in cookFoodWords(text)) {
    final forms = _saidForms(food);
    for (final word in words) {
      if (_holdsByChance(word, forms)) {
        inside = true;
      } else if (forms.any((form) => _startsOrEnds(word, form)) ||
          _isLongNameOf(word, forms)) {
        return false;
      } else {
        inside = inside || forms.any(word.contains);
      }
    }
  }
  return inside;
}

bool _startsOrEnds(String word, String food) =>
    word.startsWith(food) || word.endsWith(food);

// [word], and its singular and common word, as the matcher reads it.
Set<String> _forms(String word) => {
  word,
  ...ingredientMatchTokens(word, fallbackIngredientMatchLexicon),
};

// The forms of a word said, also without the "e" of a plural ("Pilze"), and
// the plural of "Ei", which no ending makes ("Bio-Eier").
Set<String> _saidForms(String word) {
  final forms = _forms(word);
  return {
    ...forms,
    if (word.length > 4 && word.endsWith('e'))
      word.substring(0, word.length - 1),
    if (forms.contains('ei')) 'eier',
  };
}

// Whether [word] ends with one of the [foods], with a plural ending behind it.
// A word of two letters takes no ending, or "Ei" would be the end of "Reis".
bool _endsWithFood(String word, Set<String> foods) => foods.any(
  (food) =>
      word.endsWith(food) ||
      (food.length > 2 &&
          _pluralEndings.any((ending) => word.endsWith('$food$ending'))),
);

// Whether [word] holds one of the [foods] and the rest still means it: a part
// of the same food follows, or it starts [word] and the shared rule keeps it.
// A word of two letters only counts at the start, or "Ei" would be in
// "Reisfleisch".
bool _isLongNameOf(String word, Set<String> foods) => foods.any((food) {
  final at = word.lastIndexOf(food);
  if (at < 0 || word.length == food.length) return false;
  return ((at == 0 || food.length > 2) &&
          _partOfFood.hasMatch(word.substring(at + food.length))) ||
      (word.startsWith(food) &&
          !sharesOnlyCompoundModifier(
            food: food,
            itemName: word,
            lexicon: fallbackIngredientMatchLexicon,
          ));
});

// Whether [word] holds one of the [foods] only because another food has its
// letters ("Wein" in "Bio-Schweinefilet").
bool _holdsByChance(String word, Set<String> foods) =>
    foods.any((food) => _chanceHolders[food]?.any(word.contains) ?? false);

// The foods that hold the letters of another by chance, by that other food.
const _chanceHolders = {
  'wein': ['schwein'],
  'ei': ['salbei', 'brei', 'eis'],
  'eis': ['reis'],
  'zucker': ['zuckerschote'],
};

const _pluralEndings = {'e', 'n', 'en', 's', 'es', 'er'};

// A link, parts of the same food ("Brustfilet"), and a plural ending.
final _partOfFood = RegExp(
  '^(?:en|es|er|e|n|s)?(?:fleisch|brust|filet|schenkel|keule|schote)+'
  r'(?:en|e|n|s)?$',
);

String _withoutUmlauts(String word) =>
    word.replaceAll('ä', 'a').replaceAll('ö', 'o').replaceAll('ü', 'u');

String _withoutAccents(String text) => _accents.entries.fold(
  text,
  (text, accent) => text.replaceAll(accent.value, accent.key),
);

// The letters the shared matcher would read as a space. Ä, ö, ü and ß it keeps.
final _accents = {
  'a': RegExp('[àáâãå]'),
  'ae': RegExp('æ'),
  'c': RegExp('ç'),
  'e': RegExp('[èéêë]'),
  'i': RegExp('[ìíîï]'),
  'n': RegExp('ñ'),
  'o': RegExp('[òóôõø]'),
  'oe': RegExp('œ'),
  'u': RegExp('[ùúû]'),
  'y': RegExp('[ýÿ]'),
};
