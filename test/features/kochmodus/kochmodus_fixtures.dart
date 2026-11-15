import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../recipes/cook_run_fixtures.dart';

/// A line with its own [text], which `cookLine` does not take.
CookRunLine textLine(
  String id,
  String text, {
  LineSettlement settlement = const LineOpen(),
  int? amount,
  int? amountPortions,
  TemplateIngredientUnit? amountUnit,
  int? weighed,
  String? potId,
  CookLineConversion? conversion,
  List<String> addedItemIds = const [],
  CookLineOrigin origin = CookLineOrigin.recipe,
  CookRoughWeight? roughWeight,
}) => CookRunLine(
  id: id,
  text: text,
  origin: origin,
  conversion: conversion,
  amount: amount,
  amountPortions: amount == null ? null : amountPortions ?? 4,
  amountUnit: amountUnit,
  settlement: settlement,
  weighed: weighed,
  potId: potId,
  addedItemIds: addedItemIds,
  roughWeight: roughWeight,
);

LineAssigned assigned(Map<String, int> amounts) => LineAssigned([
  for (final MapEntry(:key, :value) in amounts.entries)
    ItemTake(itemId: key, amount: value),
]);

CookRun freeRun(
  List<CookRunLine> lines, {
  CookPotChoice? pots,
  String name = 'Frei',
}) {
  final base = buildCookRun(lines: lines, pots: pots);
  return CookRun(
    id: base.id,
    kind: CookRunKind.free,
    step: base.step,
    recipeId: null,
    name: name,
    imageAssetId: null,
    imageUrl: null,
    basePortions: 1,
    portions: 1,
    steps: const [],
    startedBy: base.startedBy,
    startedByName: base.startedByName,
    startedAt: base.startedAt,
    lines: lines,
    pots: pots,
    withGuide: false,
    guideStep: 0,
    timers: const [],
    meals: const [],
    toCookbook: false,
    droppedItemIds: const [],
  );
}

const completeNutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 100,
  per100Protein: 1,
  per100Carbs: 1,
  per100Fat: 1,
);

/// An item kept in grams (or [unit]) with amount progress.
InventoryItem stockItem(
  String id,
  int amount, {
  InventoryAmountUnit unit = InventoryAmountUnit.gram,
  int scale = 1,
  int? initial,
  GlobalFoodNutrition? nutrition = completeNutrition,
  double? servingQuantity,
  String? servingQuantityUnit,
  DateTime? entryDate,
}) => InventoryItem.create(
  id: id,
  name: 'Item $id',
  entryDate: entryDate ?? DateTime.utc(2026, 10),
  storeName: 'Store',
  quantity: 1,
  initialAmount: initial ?? amount,
  currentAmount: amount,
  amountScale: scale,
  amountUnit: unit,
  nutrition: nutrition,
  servingQuantity: servingQuantity,
  servingQuantityUnit: servingQuantityUnit,
);

/// An item counted in whole packs, without amount progress.
InventoryItem packItem(String id, int quantity) => InventoryItem.create(
  id: id,
  name: 'Pack $id',
  entryDate: DateTime.utc(2026, 10),
  storeName: 'Store',
  quantity: quantity,
  initialQuantity: quantity,
  nutrition: completeNutrition,
);

Map<String, InventoryItem> byId(List<InventoryItem> items) => {
  for (final item in items) item.id: item,
};
