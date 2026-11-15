import 'dart:math' show max;

import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_line_parse.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// What the food pick ("Welches ... hast du?") gets for a line that needs
/// [need] and whose recipe gives one piece of it the weight [conversion].
///
/// A line in spoons asks by weight ([cookSpoonWeight]): the spoons, with the
/// exact quantity when it has one ("2,5 TL"), times the weight of one spoon,
/// rounded, at least 1, in the unit of that weight, and no piece weight. So
/// "Egal, irgendeins" puts the food into the Vorrat by weight, which a line in
/// spoons can take from, and a product without a package size is asked for in
/// g or ml. Any other line asks for [need] as it is, and a line in pieces
/// gives a food in pieces without a weight [conversion] as its piece weight.
({TemplateIngredientRequirement? need, int? pieceWeight}) cookPickNeed(
  TemplateIngredientRequirement? need,
  CookLineConversion? conversion,
) {
  final spoon = cookSpoonWeight(need, conversion);
  if (need == null || spoon == null) {
    return (
      need: need,
      pieceWeight: need?.unit == TemplateIngredientUnit.piece
          ? conversion?.amountPerPiece
          : null,
    );
  }
  final spoons = need.exactQuantity ?? need.amount.toDouble();
  return (
    need: TemplateIngredientRequirement(
      amount: max(1, (spoons * spoon.amountPerPiece).round()),
      unit: spoon.unit,
      name: need.name,
    ),
    pieceWeight: null,
  );
}

/// The weight of one spoon of [need] when it is a line in spoons: counted in
/// pieces that no food kept in pieces can give
/// ([TemplateIngredientRequirement.allowsDirectPieceInventoryMatch] is
/// false). That is the line's own piece weight [conversion] from the recipe,
/// else a level tablespoon or teaspoon by its measure
/// ([TemplateIngredientRequirement.countMeasureLabel]). `null` for any other
/// line, and for a scoop without the recipe's weight ("2 Tassen Reis"), whose
/// weight nobody knows.
CookLineConversion? cookSpoonWeight(
  TemplateIngredientRequirement? need,
  CookLineConversion? conversion,
) {
  if (need == null ||
      need.unit != TemplateIngredientUnit.piece ||
      need.allowsDirectPieceInventoryMatch) {
    return null;
  }
  if (_weighs(conversion)) return conversion;
  final grams = _levelSpoonGrams(need.countMeasureLabel);
  return grams == null
      ? null
      : CookLineConversion(
          amountPerPiece: grams,
          unit: TemplateIngredientUnit.gram,
        );
}

/// Whether the spoon of [need] ([cookSpoonWeight]) is only the level spoon,
/// a guess: the recipe gives no weight of one ([conversion]). Such a line
/// takes what is there when less is left, and is short only when nothing is.
bool cookSpoonGuessed(
  TemplateIngredientRequirement? need,
  CookLineConversion? conversion,
) => !_weighs(conversion) && cookSpoonWeight(need, conversion) != null;

/// The weight of [line] with the Vorrat [items] by id ([cookLineWeight]) by
/// what its amount counts in ([cookLineAmountKind]).
CookLineWeight cookLineWeightOf(
  CookRunLine line,
  Map<String, InventoryItem> items,
) => cookLineWeight(line, items, kind: cookLineAmountKind(line));

/// What the amount of [line] counts in, as its text reads
/// (`parseKochmodusLine`; the portions do not change it) or as the cook set
/// it: spoons, only a real EL or TL ([cookSpoonWeight] with a level spoon's
/// weight), which are never a weight, also with the recipe's own weight of
/// one; grams or ml; or pieces, a measure (also a cup, ladle or handful with
/// the recipe's weight) or no amount, whose weight from an item kept in grams
/// or ml is only the recipe's guess until the cook weighs it or sets an amount
/// in grams or ml. The recipe's piece weight ([CookRunLine.conversion]) does
/// not say whether the cook typed it or the recipe estimated it, so it is
/// always a guess.
CookLineAmountKind cookLineAmountKind(CookRunLine line) {
  final read = readCookLineText(const TemplateIngredientParser(), line.text);
  final unit =
      read?.unit ??
      (line.amount == null
          ? null
          // Without its unit the cook's amount counts in that of the line's
          // first item (`cookOwnAmountUnit`): a weight on one kept by weight,
          // and one kept in pieces goes by its piece size anyway.
          : line.amountUnit ?? TemplateIngredientUnit.gram);
  return cookSpoonWeight(read, line.conversion) != null &&
          _levelSpoonGrams(read?.countMeasureLabel) != null
      ? CookLineAmountKind.spoons
      : unit == null || unit == TemplateIngredientUnit.piece
      ? CookLineAmountKind.other
      : CookLineAmountKind.weight;
}

// Whether [conversion] gives one spoon a weight in g or ml.
bool _weighs(CookLineConversion? conversion) =>
    conversion != null &&
    conversion.amountPerPiece > 0 &&
    conversion.unit != TemplateIngredientUnit.piece;

/// Grams of a level tablespoon and of a level teaspoon, for a line in spoons
/// whose recipe gives no weight of one. They stand for ml as well: the food
/// estimate counts per 100 g, and g and ml count 1:1 while cooking.
const _tablespoonGrams = 15;
const _teaspoonGrams = 5;

// The grams of one spoon of [measure] ("EL", "gehäufte EL", "Teelöffel",
// "tsp"), by its last word as the ingredient parser and `cookTextScoop` keep
// it; `null` for any other measure.
int? _levelSpoonGrams(String? measure) {
  final word = (measure ?? '')
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .last
      .replaceAll(RegExp('[^a-zäöüß]'), '');
  return switch (word) {
    'el' ||
    'esslöffel' ||
    'essloeffel' ||
    'eßlöffel' ||
    'tbsp' => _tablespoonGrams,
    'tl' ||
    'teelöffel' ||
    'teeloeffel' ||
    'tsp' ||
    'teaspoon' ||
    'teaspoons' => _teaspoonGrams,
    _ => null,
  };
}
