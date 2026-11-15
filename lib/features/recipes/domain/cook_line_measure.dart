import 'package:yamt/features/recipes/domain/cook_line_text.dart';

/// Whether [text] starts with a measure of its own, in digits or in words:
/// "1 Prise Salz", "etwas Öl", "2 Zweige Rosmarin", "eine Handvoll Nüsse".
/// "Butter zum Braten" and "Salz" do not.
bool cookTextStartsWithMeasure(String text) {
  final read = normalizeCookLineText(text).trimLeft();
  if (read.startsWith(RegExp(r'[\d¼½¾⅓⅔⅛]'))) return true;
  final first = read.split(RegExp(r'\s+')).first.toLowerCase();
  return _measures.contains(first) || _articles.contains(first);
}

/// [text] split into its own measure and its food when it starts with a
/// measure word, with or without a number before it: "1 Prise" and "Salz",
/// "etwas" and "Öl", "eine Handvoll" and "Nüsse". `null` when it does not or
/// nothing follows the measure; then the text stays whole.
({String measure, String food})? cookTextMeasure(String text) {
  final match = _ownMeasure.firstMatch(text.trim());
  if (match == null || !_measures.contains(match[2]!.toLowerCase())) {
    return null;
  }
  return (measure: match[1]!.trim(), food: match[3]!.trim());
}

final _ownMeasure = RegExp(
  r'^((?:[\d¼½¾⅓⅔⅛][\d¼½¾⅓⅔⅛.,/\s]*|(?:ein|eine|einen|einer|a|an)\s+)?'
  r'([a-zA-ZäöüÄÖÜß]+)\.?)\s+(\S.*)$',
  caseSensitive: false,
);

const _articles = {'ein', 'eine', 'einen', 'einer', 'einige', 'a', 'an'};

const _measures = {
  'prise',
  'prisen',
  'msp',
  'messerspitze',
  'schuss',
  'spritzer',
  'el',
  'tl',
  'bund',
  'dose',
  'dosen',
  'packung',
  'pck',
  'päckchen',
  'becher',
  'glas',
  'zehe',
  'zehen',
  'scheibe',
  'scheiben',
  'handvoll',
  'etwas',
  'pinch',
  'dash',
  'can',
  'tbsp',
  'tsp',
  'some',
};
