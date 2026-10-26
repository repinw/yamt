import 'package:yamt/features/inventory/domain/ingredient_match_lexicon.dart';
import 'package:yamt/features/inventory/domain/ingredient_match_tokens.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Whether [item] matches [ingredient] only weakly: the food is only the
/// first part of a compound, as "Reiswaffeln" for "Reis" (#842). A weak
/// match may be picked but never supplies a line or counts as stock.
/// It reads [ingredient] with the words of all languages, so a German unit
/// ("2 EL Reis") is no food word in an English app.
bool isWeakIngredientMatch({
  required String ingredient,
  required InventoryItem item,
}) => sharesOnlyCompoundModifier(
  food: ingredient,
  itemName: item.name,
  lexicon: fallbackIngredientMatchLexicon,
);

/// Whether [food] and [itemName] share a food only as the first part of a
/// compound, as "Reis" in "Reiswaffeln" or "Milch" in "Milchreis" (#842).
///
/// A German compound names its food in its last part, so "Basmatireis" is
/// rice and "Reiswaffeln" is not. A plural or case ending ("Karotten") keeps
/// the food. Such a match is weak: the cook may pick it, but it never
/// supplies a line by itself, also not "Heringsfilet" for "Hering". Only
/// one-word foods and names are checked.
bool sharesOnlyCompoundModifier({
  required String food,
  required String itemName,
  required IngredientMatchLexicon lexicon,
}) {
  final foodWords = _words(stripIngredientMatchPrefix(food, lexicon), lexicon);
  final itemWords = _words(itemName, lexicon);
  return (foodWords.length == 1 &&
          _isModifierOnly(foodWords.single, itemWords, lexicon)) ||
      (itemWords.length == 1 &&
          _isModifierOnly(itemWords.single, foodWords, lexicon));
}

/// Whether [word] starts a longer word of [words] that names another food
/// after it ([_endsFood]), and no word of [words] is [word] or ends with
/// it.
bool _isModifierOnly(
  String word,
  List<String> words,
  IngredientMatchLexicon lexicon,
) {
  final stems = _stems(word);
  if (words.any((other) => stems.any(other.endsWith))) {
    return false;
  }
  return words.any(
    (other) => stems.any(
      (stem) =>
          other.length > stem.length &&
          other.startsWith(stem) &&
          !_endsFood(other.substring(stem.length), lexicon),
    ),
  );
}

/// [word] and its stems without an ending, as "kartoffel" for
/// "kartoffeln", so "Kartoffelpüree" names another food.
Set<String> _stems(String word) => {
  word,
  for (final ending in _endings)
    if (word.length - ending.length >= 3 && word.endsWith(ending))
      word.substring(0, word.length - ending.length),
};

// An ending, a number, or a word that names an amount of the food in a
// recipe ("zehe" in "Knoblauchzehen", "stücke" in "Tomatenstücke").
// A linking "n" or "s" may come first ("Tomate|n|stücke").
bool _endsFood(String rest, IngredientMatchLexicon lexicon) =>
    _endings.contains(rest) ||
    rest.startsWith(_digit) ||
    [
      rest,
      for (final link in _endings)
        if (rest.startsWith(link)) rest.substring(link.length),
    ].any(
      (word) =>
          lexicon.stopWords.contains(word) ||
          lexicon.prefixTokens.contains(word),
    );

/// The food words of [text] ([ingredientMatchTokens]), without words such
/// as "Bio"; a hyphen joins a compound ("Reis-Waffeln").
List<String> _words(String text, IngredientMatchLexicon lexicon) =>
    ingredientMatchTokens(
      normalizeIngredientMatchText(text.replaceAll('-', '')),
      lexicon,
    ).toList();

final _digit = RegExp('[0-9]');

/// German plural and case endings, which leave a word the same food.
const _endings = <String>{'e', 'n', 'en', 's', 'es', 'er', 'r', 'ns'};
