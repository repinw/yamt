import 'package:yamt/features/inventory/domain/cook_line_food.dart';
import 'package:yamt/features/inventory/domain/ingredient_match_lexicon.dart';
import 'package:yamt/features/inventory/domain/ingredient_match_tokens.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Whether [item] matches [ingredient] only weakly: the food is only the
/// first part of a compound, as "Reiswaffeln" for "Reis" (#842), or they
/// share only words for a kind, as "Schwarzer Tee" for "Schwarzer Pfeffer"
/// ([_sharesOnlyKindWords]). A weak match may be picked but never supplies a
/// line or counts as stock. It reads [ingredient] with the words of all
/// languages, so a German unit ("2 EL Reis") is no food word in an English app.
bool isWeakIngredientMatch({
  required String ingredient,
  required InventoryItem item,
}) =>
    sharesOnlyCompoundModifier(
      food: ingredient,
      itemName: item.name,
      lexicon: fallbackIngredientMatchLexicon,
    ) ||
    _sharesOnlyKindWords(ingredient, item.name, fallbackIngredientMatchLexicon);

/// Whether the food of the line [text] ([cookLineFoodPhrase]) and [itemName]
/// share words, and each word they share is a word for a kind
/// ([IngredientMatchLexicon.kindWords]): "schwarzer" of "Schwarzer Pfeffer"
/// and "Schwarzer Tee", "rote" of "Rote Linsen" and "Rote Bete". One shared
/// word that names a food ("Zwiebeln" of "2 Zwiebeln, fein gewürfelt" and
/// "Zwiebeln rot") makes it a normal match; so does a spelling one letter
/// apart ("Rote Beete", "Rote Bete").
bool _sharesOnlyKindWords(
  String text,
  String itemName,
  IngredientMatchLexicon lexicon,
) {
  final itemWords = _words(itemName, lexicon);
  final shared = [
    for (final word in _words(cookLineFoodPhrase(text), lexicon))
      for (final other in itemWords)
        if (_sameWord(word, other) || _oneLetterApart(word, other))
          (word, other),
  ];
  return shared.isNotEmpty &&
      shared.every(
        (pair) =>
            isIngredientKindWord(pair.$1, lexicon) ||
            isIngredientKindWord(pair.$2, lexicon),
      );
}

/// Whether [a] and [b] are one word, also with an ending ("schwarze",
/// "schwarzer") or as the head of a compound ("Pfeffer", "Cayennepfeffer").
bool _sameWord(String a, String b) =>
    _stems(a).any(b.endsWith) || _stems(b).any(a.endsWith);

/// Whether [a] and [b], both of four letters or more, differ in one letter
/// left out, added or swapped for another.
bool _oneLetterApart(String a, String b) {
  if (a.length < 4 || b.length < 4 || (a.length - b.length).abs() > 1) {
    return false;
  }
  final (long, short) = a.length >= b.length ? (a, b) : (b, a);
  var start = 0;
  while (start < short.length && long[start] == short[start]) {
    start++;
  }
  if (start == short.length) return true;
  final skip = long.length == short.length ? start + 1 : start;
  return long.substring(start + 1) == short.substring(skip);
}

/// Whether [word], in lower case, is a word for a kind of [lexicon], also
/// with an ending ("schwarzer", "saure", "dunkle"): it names no food by
/// itself.
bool isIngredientKindWord(String word, IngredientMatchLexicon lexicon) =>
    lexicon.kindWords.any(
      (kind) =>
          [
            kind,
            if (kind.endsWith('el') || kind.endsWith('er'))
              '${kind.substring(0, kind.length - 2)}${kind[kind.length - 1]}',
          ].any(
            (stem) =>
                word.startsWith(stem) &&
                _kindEndings.contains(word.substring(stem.length)),
          ),
    );

/// Whether [food] and [itemName] share a food only as the first part of a
/// compound, as "Reis" in "Reiswaffeln" or "Milch" in "Milchreis" (#842).
///
/// A German compound names its food in its last part, so "Basmatireis" is
/// rice and "Reiswaffeln" is not. A plural or case ending ("Karotten") keeps
/// the food. Such a match is weak: the cook may pick it, but it never
/// supplies a line by itself, also not "Heringsfilet" for "Hering". Names of
/// several words count too ("Fettarme H-Milch" for "Milchreis"), unless the
/// two share a whole word ([_sameWord]), as "Milch" and "Fettarme Milch", or
/// one spells the compound of the other in two words ("Mandel Mus" for
/// "Mandelmus").
bool sharesOnlyCompoundModifier({
  required String food,
  required String itemName,
  required IngredientMatchLexicon lexicon,
}) {
  final foodWords = _words(stripIngredientMatchPrefix(food, lexicon), lexicon);
  final itemWords = _words(itemName, lexicon);
  if (foodWords.any(
    (word) => itemWords.any((other) => _sameWord(word, other)),
  )) {
    return false;
  }
  return _startsOtherFood(foodWords, itemWords, lexicon) ||
      _startsOtherFood(itemWords, foodWords, lexicon);
}

/// Whether a word of [words] starts a longer word of [others] that names
/// another food after it ([_endsFood]), unless the word after it in [words]
/// spells that rest ([_spellsRest]): "Mandel Mus" is "Mandelmus" and
/// "Vollkorn Weizenmehl" is "Vollkornmehl", but "Hafer Drink" is no
/// "Hafermilch" and "Pastasauce Tomate" no "Tomatensauce".
bool _startsOtherFood(
  List<String> words,
  List<String> others,
  IngredientMatchLexicon lexicon,
) => words.indexed.any(
  (entry) => others.any(
    (other) => _stems(entry.$2).any((stem) {
      if (other.length <= stem.length || !other.startsWith(stem)) return false;
      final rest = other.substring(stem.length);
      final next = words.elementAtOrNull(entry.$1 + 1);
      return !_endsFood(rest, lexicon) &&
          (next == null || !_spellsRest(rest, next));
    }),
  ),
);

/// Whether [next] is [rest], the end of a compound after an optional linking
/// letter ("Rind|er|hack"), or ends with it when it has three letters or more
/// ("mehl" of "Weizenmehl"). The singular takes the last "s" or "n" of a long
/// word only, so "Mandelmus" has the rest "mu" of "Mus".
bool _spellsRest(String rest, String next) {
  final nexts = [
    next,
    if (next.endsWith('s') || next.endsWith('n'))
      next.substring(0, next.length - 1),
  ];
  return [
    rest,
    for (final link in _endings)
      if (rest.startsWith(link)) rest.substring(link.length),
  ].any(
    (part) => nexts.any(
      (word) => word == part || (part.length > 2 && word.endsWith(part)),
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
/// as "Bio"; a hyphen joins a compound ("Reis-Waffeln"), whose last part
/// names its food as a word of its own ("Milch" of "H-Milch").
List<String> _words(String text, IngredientMatchLexicon lexicon) =>
    ingredientMatchTokens(
      normalizeIngredientMatchText(
        [
          text.replaceAll('-', ''),
          for (final word in text.split(_whitespace))
            if (word.contains('-')) word.split('-').last,
        ].join(' '),
      ),
      lexicon,
    ).toList();

final _digit = RegExp('[0-9]');
final _whitespace = RegExp(r'\s+');

/// German plural and case endings, which leave a word the same food.
const _endings = <String>{'e', 'n', 'en', 's', 'es', 'er', 'r', 'ns'};

/// The endings of a word for a kind, as "schwarz|er".
const _kindEndings = <String>{'', 'e', 'er', 'es', 'en', 'em'};
