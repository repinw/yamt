import 'package:yamt/features/cookbook_new/domain/scanned_ingredient_list.dart';

/// Reads a recipe pasted as text, like the scan reads photos.
///
/// Headings such as "Zutaten" and "Zubereitung" or "Schritte" split the
/// ingredients from the steps. With an ingredients heading alone, the steps
/// start after an empty line, at the first line that does not go on with an
/// amount or a sub-heading; a numbered line such as "1. Mischen" does not.
/// Without headings, the lines up to the first empty line are ingredients and
/// the rest are steps.
/// Text before the first heading, or a lone first line before two more
/// blocks, holds the title and the portions ("– 2 Portionen", "Serves 4"); a
/// line with nothing but the portions is no title. An ingredient keeps its
/// text but loses its bullet, and a sub-heading such as "Für den Teig:" is
/// left out; a step loses its number or bullet. A line about kcal among the
/// steps, such as a closing nutrition note, is left out.
ScannedIngredientList readPastedRecipe(String text) {
  final lines = [for (final line in text.split(_newline)) line.trim()];
  final firstHeading = lines.indexWhere(
    (line) =>
        _ingredientsHeading.hasMatch(line) || _stepsHeading.hasMatch(line),
  );
  final List<String> head;
  final List<String> ingredients;
  final List<String> steps;
  if (firstHeading >= 0) {
    head = lines.sublist(0, firstHeading);
    ingredients = [];
    steps = [];
    final hasStepsHeading = lines
        .skip(firstHeading)
        .any(_stepsHeading.hasMatch);
    var current = ingredients;
    var afterGap = false;
    for (final line in lines.skip(firstHeading)) {
      if (_ingredientsHeading.hasMatch(line)) {
        head.add(line);
        current = ingredients;
      } else if (_stepsHeading.hasMatch(line)) {
        current = steps;
      } else if (line.isNotEmpty) {
        if (afterGap &&
            !hasStepsHeading &&
            identical(current, ingredients) &&
            ingredients.any((line) => !_subHeading.hasMatch(line)) &&
            !_continuesIngredients(line)) {
          current = steps;
        }
        current.add(line);
      }
      afterGap = line.isEmpty;
    }
  } else {
    final blocks = _blocks(lines);
    // A lone first line before ingredients and steps is the title.
    final hasTitle =
        blocks.length > 2 &&
        blocks.first.length == 1 &&
        !_startsWithAmount.hasMatch(blocks.first.single);
    final rest = hasTitle ? blocks.skip(1).toList() : blocks;
    head = hasTitle ? blocks.first : const [];
    ingredients = rest.firstOrNull ?? const [];
    steps = [for (final block in rest.skip(1)) ...block];
  }
  final title = head
      .where(
        (line) =>
            line.isNotEmpty &&
            !_ingredientsHeading.hasMatch(line) &&
            !_servingsOnly.hasMatch(line),
      )
      .firstOrNull;
  return ScannedIngredientList(
    title: title == null ? null : _titleOf(title),
    servings: _servingsIn(head),
    ingredients: [
      for (final line in ingredients)
        if (!_subHeading.hasMatch(line)) line.replaceFirst(_bullet, '').trim(),
    ],
    steps: [
      for (final line in steps)
        if (!_nutritionNote.hasMatch(line) || _stepMark.hasMatch(line))
          line.replaceFirst(_stepMark, '').trim(),
    ],
  );
}

final _newline = RegExp(r'\r?\n');

// The end of a heading line: a colon, or an ending that starts with für or
// for, a bracket, a dash, or a number, such as "für 2 Portionen". Other words
// make it a line of its own: "Zutaten vermengen", "Zubereitung: 30 Minuten".
const _headingEnding =
    r'\b(?:(?:\s*[(–—-]|\s+(?:(?:für|for)\b|\d))[^.]{0,30})?\s*:?$';
// An ingredients heading also takes other words before a closing colon, as in
// "Zutaten Teig:". A steps heading does not: "Preparation time:" is none.
final _ingredientsHeading = RegExp(
  '^(zutaten|zutatenliste|ingredients|einkaufsliste)'
  '(?:\\s+[^.:]{1,30}:\$|$_headingEnding)',
  caseSensitive: false,
);
final _stepsHeading = RegExp(
  '^(zubereitung|zubereitungsschritte|schritte|arbeitsschritte|anleitung|'
  'anweisungen|so geht.s|instructions|steps|directions|method|'
  'preparation(?: method| steps)?)$_headingEnding',
  caseSensitive: false,
);

final _bullet = RegExp(r'^[-–•*▢□]\s*');
// A list line that only names a part of the recipe, such as "Für den Teig:".
final _subHeading = RegExp(r'^[^\d]*:$');
// "1." or "2)" or a bullet; the "1." of "1.5 l" is no step number.
final _stepMark = RegExp(r'^(\d+[.)](?!\d)|[-–•*])\s*');
final _numberedStep = RegExp(r'^\d+[.)](?!\d)');
// "5-Minuten-Salat" starts with a digit but is no amount; "2-3 Eier" is one.
final _startsWithAmount = RegExp(r'^[-–•*]?\s*\d(?!\d*-\p{L})', unicode: true);
final _nutritionNote = RegExp(r'\bkcal\b', caseSensitive: false);
// "2 Portionen", "Für 4 Personen" or "Serves 4", "Portionen: 6".
final _servings = RegExp(
  r'(\d+)\s*(?:portionen|portion|personen|person|servings)\b'
  r'|\b(?:portionen|portion|personen|servings|serves|yields?)\b\s*:?\s*(\d+)',
  caseSensitive: false,
);
// A line with nothing but the portions, in either order.
final _servingsOnly = RegExp(
  r'^(?:(?:für|for)\s+)?\d+\s*(?:portionen|portion|personen|person|servings)\W*$'
  r'|^(?:portionen|portion|personen|servings|serves|yields?)\b\s*:?\s*\d+\W*$',
  caseSensitive: false,
);
// "GERICHT A: …" or "Rezept: …" before the dish name.
final _titleLabel = RegExp(
  r'^(rezept|recipe|gericht(\s+\w+)?)\s*:\s+',
  caseSensitive: false,
);
// " – 2 Portionen (ca. 40 Min)" or " (für 4 Personen)" after the name.
final _titleTail = RegExp(r'\s+[–—-]\s+.*$|\s*\(.*$');

// Whether a line after an empty line still belongs to the ingredients: a
// sub-heading or an amount, but no numbered step and no note about kcal.
bool _continuesIngredients(String line) =>
    _subHeading.hasMatch(line) ||
    (_startsWithAmount.hasMatch(line) &&
        !_numberedStep.hasMatch(line) &&
        !_nutritionNote.hasMatch(line));

List<List<String>> _blocks(List<String> lines) {
  final blocks = <List<String>>[];
  var block = <String>[];
  for (final line in lines) {
    if (line.isEmpty) {
      if (block.isNotEmpty) {
        blocks.add(block);
        block = [];
      }
    } else {
      block.add(line);
    }
  }
  if (block.isNotEmpty) {
    blocks.add(block);
  }
  return blocks;
}

String _titleOf(String line) {
  final name = line
      .replaceFirst(_titleLabel, '')
      .replaceFirst(_titleTail, '')
      .trim();
  return name.isEmpty ? line : name;
}

int? _servingsIn(List<String> lines) {
  for (final line in lines) {
    if (_servings.firstMatch(line) case final match?) {
      final count = int.parse(match.group(1) ?? match.group(2)!);
      if (count > 0) {
        return count;
      }
    }
  }
  return null;
}
