import 'dart:math' show max;

import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// [ingredient] as [parser] reads it from its normal form
/// (`normalizeCookLineText`: "½ Zitrone", "zwei Zwiebeln", "1,250 kg Mehl")
/// for [selectedPortions] of [basePortions], without rounding to whole units
/// first: the amount rounded once, at least 1, and for a line in pieces or
/// spoons the exact quantity (2.5 for "1 TL" at 5 of 2 portions, 0.5 for "1/2
/// Zitrone"). It names no count of packs. `null` when [ingredient] names no
/// amount that can be read. The recipe page and the Kochmodus read a line's
/// amount through here.
TemplateIngredientRequirement? parseIngredientExactly(
  TemplateIngredientParser parser,
  String ingredient, {
  int selectedPortions = 1,
  int basePortions = 1,
}) {
  final read = parser.parseRequirement(
    ingredient: ingredient,
    // The parser rounds to whole units; this keeps three decimals of them.
    selectedPortions: selectedPortions * _thousand,
    basePortions: basePortions,
  );
  if (read == null) return null;
  final quantity = read.amount / _thousand;
  return TemplateIngredientRequirement(
    amount: max(1, quantity.round()),
    unit: read.unit,
    name: read.name,
    countMeasureLabel: read.countMeasureLabel,
    allowsDirectPieceInventoryMatch: read.allowsDirectPieceInventoryMatch,
    exactQuantity: read.unit == TemplateIngredientUnit.piece ? quantity : null,
  );
}

/// The number of [requirement] as a cook reads it, with its exact quantity
/// when it has one: whole ("2"), a fraction below 1 ("1/2", "1/4"), or with a
/// decimal comma ("2,5").
String ingredientQuantityText(TemplateIngredientRequirement requirement) {
  final quantity = requirement.exactQuantity ?? requirement.amount.toDouble();
  final whole = quantity.round();
  if (_isWhole(quantity)) return '$whole';
  if (quantity < 1) {
    for (final under in _fractionsUnder) {
      final over = (quantity * under).round();
      if (over > 0 && (quantity - over / under).abs() < _tolerance) {
        return '$over/$under';
      }
    }
  }
  return quantity
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst('.', ',');
}

/// Whether [need] holds a part of a unit, which a whole number cannot say:
/// "1/2 Zitrone", "1,5 EL Öl".
bool cookNeedHasPart(TemplateIngredientRequirement? need) {
  final exact = need?.exactQuantity;
  return exact != null && !_isWhole(exact);
}

bool _isWhole(double quantity) =>
    (quantity - quantity.round()).abs() < _tolerance;

const _thousand = 1000;
const _tolerance = 0.002;
const _fractionsUnder = [2, 3, 4, 5, 6, 8];
