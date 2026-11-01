import 'package:collection/collection.dart';

/// The food a recipe line names, for its letter tile: the first capitalized
/// word after a leading amount that is no measure word, such as "Salz" for
/// "1 Prise Salz" and "Zwiebel" for "mittlere Zwiebel".
String cookLineFood(String text) {
  final words = text
      .replaceFirst(_leadingAmount, '')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return text.trim();
  final foods = words.where((word) => !_measures.contains(word.toLowerCase()));
  return foods.firstWhereOrNull((word) => word[0] != word[0].toLowerCase()) ??
      foods.firstOrNull ??
      words.first;
}

final _leadingAmount = RegExp(r'^[\s\d¼½¾⅓⅔⅛.,/-]+');

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
