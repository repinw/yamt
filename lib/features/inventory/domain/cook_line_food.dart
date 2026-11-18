import 'dart:math' show max;

import 'package:yamt/features/inventory/domain/ingredient_match_lexicon.dart';
import 'package:yamt/features/inventory/domain/ingredient_match_tokens.dart';
import 'package:yamt/features/recipes/domain/cook_line_measure.dart';
import 'package:yamt/features/recipes/domain/cook_line_text.dart';

/// The food a recipe line names, short: the capitalized words that start its
/// [cookLineFoodName] up to a comma or a small word, else that whole name.
/// "Schwarzer Pfeffer" for "1/2 TL Schwarzer Pfeffer", "Oregano" for "1 TL
/// Oregano getrocknet", "Butter" for "Butter zum Braten", "Salz" for "1 Prise
/// Salz", "rote linsen" for "200 g rote linsen". For the letter tile, the name
/// of free cooking and the Vorrat foods a line names.
String cookLineFood(String text) {
  final words = cookLineFoodName(text).split(',').first.trim().split(' ');
  final lead = words.takeWhile(_capitalized);
  return lead.isEmpty ? words.join(' ') : lead.join(' ');
}

/// The name of the food a line names, for asking which it is and searching
/// it: [cookLineFoodPhrase], and without small words while a capitalized word
/// follows them. "Schwarzer Pfeffer" for "1/2 TL Schwarzer Pfeffer",
/// "Frischkäse" for "100 g Frischkäse (Doppelrahmstufe)", "Zwiebel" for "1
/// mittlere Zwiebel", "rote linsen" for "200 g rote linsen", "flour" for "1
/// cup of flour", "Butter" for "Butter 100 g". [text] trimmed when nothing but
/// an amount and measure words is left ("200 g", "1 Prise").
String cookLineFoodName(String text) {
  var name = _foodPart(text);
  while (true) {
    final words = _withoutMeasure(name);
    if (words.every(_measureWord)) return text.trim();
    final capital = words.indexWhere(_capitalized);
    final next = words.skip(max(0, capital)).join(' ');
    if (next == name) return name;
    name = next;
  }
}

/// The words of the food a line names, as they stand: [text] without
/// additions in brackets, up to its first comma (an amount or how it is cut,
/// "Öl, 30 g", "Zwiebel, fein gewürfelt"), without an amount at its end
/// ("Butter 100 g", "Mehl 200", "à 400 g"), and without its amount and the
/// measure words before its food (`stripIngredientMatchPrefix`,
/// [cookTextMeasure]) or an "of" after them. "rote Linsen" for "200 g rote
/// Linsen, gewaschen", where [cookLineFoodName] keeps only "Linsen".
String cookLineFoodPhrase(String text) =>
    _withoutMeasure(_foodPart(text)).join(' ');

String _foodPart(String text) {
  final name = normalizeCookLineText(
    text.replaceAll(_brackets, ' ').split(_partComma).first,
  ).trim();
  final amount = _trailingAmount.firstMatch(name);
  return amount == null || !_letter.hasMatch(name.substring(0, amount.start))
      ? name
      : name.substring(0, amount.start);
}

List<String> _withoutMeasure(String name) =>
    stripIngredientMatchPrefix(
          cookTextMeasure(name)?.food ?? name,
          fallbackIngredientMatchLexicon,
        )
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .skipWhile(_of)
        .toList();

final _brackets = RegExp(r'\([^)]*\)');

// An amount at the end of a name, also per pack ("Tomaten à 400 g"), but no
// type number ("Weizenmehl Type 405").
final _trailingAmount = RegExp(
  r'(?<!\btype?\s*)\s+(?:(?:je|à|á)\s*)?(?:\d+/\d+|\d+(?:[.,]\d+)?)\s*'
  r'(?:g|gr|gramm|kg|ml|cl|dl|l)?$',
  caseSensitive: false,
);
final _letter = RegExp('[a-zA-ZäöüÄÖÜß]');

// A comma that is no decimal comma ("1,5 kg").
final _partComma = RegExp(r'(?<!\d),|,(?!\d)');

bool _of(String word) => word.toLowerCase() == 'of';

// Whether [word] names only an amount or a measure, such as "g" or "Prise".
bool _measureWord(String word) => fallbackIngredientMatchLexicon.prefixTokens
    .contains(normalizeIngredientMatchText(word).replaceAll(' ', ''));

bool _capitalized(String word) =>
    word.isNotEmpty && word[0] != word[0].toLowerCase();
