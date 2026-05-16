// Internal detail helpers are public only for sibling split files.
// ignore_for_file: public_member_api_docs

import 'package:yamt/features/inventory/application/'
    'ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart'
    show PreparedMealCreationFailureReason;
import 'package:yamt/features/inventory/application/'
    'recipe_ingredient_assignment_support.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum IngredientCardState { plain, missing, matched, ignored }

class IngredientRowData {
  const IngredientRowData({
    required this.name,
    required this.amountLabel,
    this.rawIngredient,
    this.isIgnored = false,
    this.assignedInventoryItemIds = const <String>[],
    this.requirement,
    this.amountConversion,
  });

  final String name;
  final String amountLabel;
  final String? rawIngredient;
  final bool isIgnored;
  final List<String> assignedInventoryItemIds;
  final TemplateIngredientRequirement? requirement;
  final RecipeIngredientAmountConversion? amountConversion;
}

/// Defines meal template ingredient assignment selection.
class MealTemplateIngredientAssignmentSelection {
  /// The meal template ingredient assignment selection.
  const MealTemplateIngredientAssignmentSelection({
    this.inventoryItemIds = const <String>[],
    this.amountConversion,
  });

  /// The inventory item ids.
  final List<String> inventoryItemIds;

  /// The amount conversion.
  final RecipeIngredientAmountConversion? amountConversion;
}

PreparedMeal? findTemplate({
  required List<PreparedMeal> templates,
  required String templateId,
}) {
  for (final template in templates) {
    if (template.id == templateId) {
      return template;
    }
  }
  return null;
}

int defaultPortions(int totalPortions) {
  return totalPortions > 0 ? totalPortions : 1;
}

Map<String, List<String>> effectiveAssignments({
  required PreparedMeal template,
  required Map<String, List<String>>? draftAssignments,
  required List<InventoryItem> inventoryItems,
  required TemplateIngredientParser ingredientParser,
  required String localeCode,
}) {
  final normalizedAssignments = draftAssignments == null
      ? _normalizedAssignments(template.recipeIngredientAssignments)
      : _normalizedAssignments(draftAssignments);
  if (draftAssignments != null) {
    return normalizedAssignments;
  }

  return _withAutomaticAssignments(
    template: template,
    assignments: normalizedAssignments,
    inventoryItems: inventoryItems,
    ingredientParser: ingredientParser,
    localeCode: localeCode,
  );
}

Map<String, List<String>> updatedAssignments({
  required Map<String, List<String>> assignments,
  required String ingredient,
  required List<String> inventoryItemIds,
}) {
  final nextAssignments = <String, List<String>>{...assignments};
  final normalizedIngredient = ingredient.trim();
  final normalizedItemIds = inventoryItemIds
      .map((itemId) => itemId.trim())
      .where((itemId) => itemId.isNotEmpty)
      .toSet()
      .toList(growable: false);
  if (normalizedItemIds.isEmpty) {
    nextAssignments.remove(normalizedIngredient);
  } else {
    nextAssignments[normalizedIngredient] = normalizedItemIds;
  }
  return nextAssignments;
}

Map<String, List<String>> _normalizedAssignments(
  Map<String, List<String>> assignments,
) {
  final normalized = <String, List<String>>{};
  for (final entry in assignments.entries) {
    final ingredient = entry.key.trim();
    if (ingredient.isEmpty) {
      continue;
    }
    final itemIds = entry.value
        .map((itemId) => itemId.trim())
        .where((itemId) => itemId.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (itemIds.isEmpty) {
      continue;
    }
    normalized[ingredient] = itemIds;
  }
  return normalized;
}

Map<String, RecipeIngredientAmountConversion> _normalizedAssignmentConversions(
  Map<String, RecipeIngredientAmountConversion> conversions,
) {
  final normalized = <String, RecipeIngredientAmountConversion>{};
  for (final entry in conversions.entries) {
    final ingredient = entry.key.trim();
    final conversion = entry.value;
    if (ingredient.isEmpty ||
        conversion.amountPerPiece < 1 ||
        conversion.unit == InventoryAmountUnit.piece) {
      continue;
    }
    normalized[ingredient] = conversion;
  }
  return normalized;
}

bool assignmentMapsEqual(
  Map<String, List<String>> left,
  Map<String, List<String>> right,
) {
  final normalizedLeft = _normalizedAssignments(left);
  final normalizedRight = _normalizedAssignments(right);
  if (normalizedLeft.length != normalizedRight.length) {
    return false;
  }

  for (final entry in normalizedLeft.entries) {
    final otherValue = normalizedRight[entry.key];
    if (otherValue == null) {
      return false;
    }
    final leftIds = entry.value.toSet();
    final rightIds = otherValue.toSet();
    if (leftIds.length != rightIds.length || !leftIds.containsAll(rightIds)) {
      return false;
    }
  }
  return true;
}

bool assignmentConversionMapsEqual(
  Map<String, RecipeIngredientAmountConversion> left,
  Map<String, RecipeIngredientAmountConversion> right,
) {
  final normalizedLeft = _normalizedAssignmentConversions(left);
  final normalizedRight = _normalizedAssignmentConversions(right);
  if (normalizedLeft.length != normalizedRight.length) {
    return false;
  }

  for (final entry in normalizedLeft.entries) {
    if (normalizedRight[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

Map<String, RecipeIngredientAmountConversion> updatedAssignmentConversions({
  required Map<String, RecipeIngredientAmountConversion> conversions,
  required String ingredient,
  required RecipeIngredientAmountConversion? amountConversion,
}) {
  final nextConversions = <String, RecipeIngredientAmountConversion>{
    ...conversions,
  };
  final normalizedIngredient = ingredient.trim();
  if (normalizedIngredient.isEmpty ||
      amountConversion == null ||
      amountConversion.amountPerPiece < 1 ||
      amountConversion.unit == InventoryAmountUnit.piece) {
    nextConversions.remove(normalizedIngredient);
    return nextConversions;
  }

  nextConversions[normalizedIngredient] = amountConversion;
  return nextConversions;
}

Map<String, List<String>> _withAutomaticAssignments({
  required PreparedMeal template,
  required Map<String, List<String>> assignments,
  required List<InventoryItem> inventoryItems,
  required TemplateIngredientParser ingredientParser,
  required String localeCode,
}) {
  if (template.recipeIngredients.isEmpty || inventoryItems.isEmpty) {
    return assignments;
  }

  final inventoryItemIds = inventoryItems
      .map((item) => item.id.trim())
      .where((itemId) => itemId.isNotEmpty)
      .toSet();
  final nextAssignments = <String, List<String>>{
    for (final entry in assignments.entries)
      if (_validAssignmentIds(entry.value, inventoryItemIds).isNotEmpty)
        entry.key.trim(): _validAssignmentIds(entry.value, inventoryItemIds),
  };
  final reservedItemIds = <String>{
    for (final itemIds in nextAssignments.values) ...itemIds,
  };
  final ignoredIngredients = template.ignoredRecipeIngredients
      .map((ingredient) => ingredient.trim())
      .where((ingredient) => ingredient.isNotEmpty)
      .toSet();

  for (final ingredient in template.recipeIngredients) {
    final normalizedIngredient = ingredient.trim();
    if (normalizedIngredient.isEmpty ||
        ignoredIngredients.contains(normalizedIngredient) ||
        _assignmentIdsForIngredient(nextAssignments, ingredient).isNotEmpty) {
      continue;
    }

    final requirement = ingredientParser.parseRequirement(
      ingredient: ingredient,
      selectedPortions: 1,
      basePortions: 1,
    );
    final matches =
        matchInventoryItemsForIngredient(
          ingredient: ingredient,
          inventoryItems: inventoryItems,
          localeCode: localeCode,
        ).where(
          (item) =>
              canAutoAssignInventoryItem(requirement: requirement, item: item),
        );
    for (final item in matches) {
      if (reservedItemIds.contains(item.id)) {
        continue;
      }
      nextAssignments[normalizedIngredient] = <String>[item.id];
      reservedItemIds.add(item.id);
      break;
    }
  }

  return nextAssignments;
}

List<IngredientRowData> buildIngredientRows({
  required PreparedMeal template,
  required Map<String, List<String>> recipeIngredientAssignments,
  required Map<String, RecipeIngredientAmountConversion>
  recipeIngredientAmountConversions,
  required int selectedPortions,
  required TemplateIngredientParser ingredientParser,
}) {
  if (template.components.isNotEmpty) {
    return template.components
        .map(
          (component) => IngredientRowData(
            name: component.name,
            amountLabel: _scaledComponentAmount(
              component: component,
              selectedPortions: selectedPortions,
              basePortions: template.totalPortions,
            ),
          ),
        )
        .toList(growable: false);
  }

  return template.recipeIngredients
      .map((ingredient) {
        final requirement = ingredientParser.parseRequirement(
          ingredient: ingredient,
          selectedPortions: selectedPortions,
          basePortions: template.totalPortions,
        );
        return _scaledRecipeIngredient(
          ingredient,
          isIgnored: _containsNormalizedIngredient(
            template.ignoredRecipeIngredients,
            ingredient,
          ),
          assignedInventoryItemIds: _assignmentIdsForIngredient(
            recipeIngredientAssignments,
            ingredient,
          ),
          requirement: requirement,
          amountConversion: _assignmentConversionForIngredient(
            recipeIngredientAmountConversions,
            ingredient,
          ),
          selectedPortions: selectedPortions,
          basePortions: template.totalPortions,
        );
      })
      .toList(growable: false);
}

IngredientRowData _scaledRecipeIngredient(
  String ingredient, {
  required bool isIgnored,
  required List<String> assignedInventoryItemIds,
  required TemplateIngredientRequirement? requirement,
  required RecipeIngredientAmountConversion? amountConversion,
  required int selectedPortions,
  required int basePortions,
}) {
  final trimmed = ingredient.trim();
  final quantityWithUnitMatch = RegExp(
    r'^(\d+(?:[.,]\d+)?)\s+(\S+)\s+(.+)$',
  ).firstMatch(trimmed);
  if (quantityWithUnitMatch != null) {
    final rawQuantity = quantityWithUnitMatch.group(1);
    final unit = quantityWithUnitMatch.group(2);
    final name = quantityWithUnitMatch.group(3);
    if (rawQuantity == null || unit == null || name == null) {
      return _fallbackIngredientRow(
        ingredient: ingredient,
        isIgnored: isIgnored,
        assignedInventoryItemIds: assignedInventoryItemIds,
        requirement: requirement,
        amountConversion: amountConversion,
      );
    }

    return _scaledParsedIngredient(
      ingredient: ingredient,
      rawQuantity: rawQuantity,
      name: name,
      amountSuffix: unit,
      isIgnored: isIgnored,
      assignedInventoryItemIds: assignedInventoryItemIds,
      requirement: requirement,
      amountConversion: amountConversion,
      selectedPortions: selectedPortions,
      basePortions: basePortions,
    );
  }

  final quantityOnlyMatch = RegExp(
    r'^(\d+(?:[.,]\d+)?)\s+(.+)$',
  ).firstMatch(trimmed);
  if (quantityOnlyMatch != null) {
    final rawQuantity = quantityOnlyMatch.group(1);
    final name = quantityOnlyMatch.group(2);
    if (rawQuantity == null || name == null) {
      return _fallbackIngredientRow(
        ingredient: ingredient,
        isIgnored: isIgnored,
        assignedInventoryItemIds: assignedInventoryItemIds,
        requirement: requirement,
        amountConversion: amountConversion,
      );
    }

    return _scaledParsedIngredient(
      ingredient: ingredient,
      rawQuantity: rawQuantity,
      name: name,
      amountSuffix: null,
      isIgnored: isIgnored,
      assignedInventoryItemIds: assignedInventoryItemIds,
      requirement: requirement,
      amountConversion: amountConversion,
      selectedPortions: selectedPortions,
      basePortions: basePortions,
    );
  }

  if (requirement != null) {
    return _ingredientRowFromRequirement(
      ingredient: ingredient,
      isIgnored: isIgnored,
      assignedInventoryItemIds: assignedInventoryItemIds,
      requirement: requirement,
      amountConversion: amountConversion,
    );
  }

  return _fallbackIngredientRow(
    ingredient: ingredient,
    isIgnored: isIgnored,
    assignedInventoryItemIds: assignedInventoryItemIds,
    requirement: requirement,
    amountConversion: amountConversion,
  );
}

IngredientRowData _ingredientRowFromRequirement({
  required String ingredient,
  required bool isIgnored,
  required List<String> assignedInventoryItemIds,
  required TemplateIngredientRequirement requirement,
  required RecipeIngredientAmountConversion? amountConversion,
}) {
  final countMeasureLabel = requirement.countMeasureLabel?.trim();
  final packageCountLabel = requirement.packageCountLabel?.trim();
  return IngredientRowData(
    name: requirement.name,
    amountLabel:
        packageCountLabel?.isNotEmpty == true &&
            requirement.unit != TemplateIngredientUnit.piece
        ? '$packageCountLabel ${requirement.amount}${requirement.unit.code}'
        : [
            requirement.amount.toString(),
            if (countMeasureLabel?.isNotEmpty == true)
              countMeasureLabel!
            else
              requirement.unit.code,
          ].join(' '),
    rawIngredient: ingredient,
    isIgnored: isIgnored,
    assignedInventoryItemIds: assignedInventoryItemIds,
    requirement: requirement,
    amountConversion: amountConversion,
  );
}

IngredientRowData _scaledParsedIngredient({
  required String ingredient,
  required String rawQuantity,
  required String name,
  required String? amountSuffix,
  required bool isIgnored,
  required List<String> assignedInventoryItemIds,
  required TemplateIngredientRequirement? requirement,
  required RecipeIngredientAmountConversion? amountConversion,
  required int selectedPortions,
  required int basePortions,
}) {
  final trimmedName = name.trim();
  final baseAmountLabel = [rawQuantity, ?amountSuffix].join(' ');
  final parsedQuantity = double.tryParse(rawQuantity.replaceAll(',', '.'));
  if (parsedQuantity == null || basePortions <= 0) {
    return IngredientRowData(
      name: trimmedName,
      amountLabel: baseAmountLabel,
      rawIngredient: ingredient,
      isIgnored: isIgnored,
      assignedInventoryItemIds: assignedInventoryItemIds,
      requirement: requirement,
      amountConversion: amountConversion,
    );
  }

  final scaledQuantity = parsedQuantity * selectedPortions / basePortions;
  final scaledAmountLabel = [
    _formatAmount(scaledQuantity),
    ?amountSuffix,
  ].join(' ');
  return IngredientRowData(
    name: trimmedName,
    amountLabel: scaledAmountLabel,
    rawIngredient: ingredient,
    isIgnored: isIgnored,
    assignedInventoryItemIds: assignedInventoryItemIds,
    requirement: requirement,
    amountConversion: amountConversion,
  );
}

IngredientRowData _fallbackIngredientRow({
  required String ingredient,
  required bool isIgnored,
  required List<String> assignedInventoryItemIds,
  required TemplateIngredientRequirement? requirement,
  required RecipeIngredientAmountConversion? amountConversion,
}) {
  final trimmed = ingredient.trim();
  return IngredientRowData(
    name: trimmed,
    amountLabel: '-',
    rawIngredient: ingredient,
    isIgnored: isIgnored,
    assignedInventoryItemIds: assignedInventoryItemIds,
    requirement: requirement,
    amountConversion: amountConversion,
  );
}

List<String> _assignmentIdsForIngredient(
  Map<String, List<String>> assignments,
  String ingredient,
) {
  final normalizedIngredient = ingredient.trim();
  if (normalizedIngredient.isEmpty) {
    return const <String>[];
  }
  return assignments[normalizedIngredient] ?? const <String>[];
}

RecipeIngredientAmountConversion? _assignmentConversionForIngredient(
  Map<String, RecipeIngredientAmountConversion> conversions,
  String ingredient,
) {
  final normalizedIngredient = ingredient.trim();
  if (normalizedIngredient.isEmpty) {
    return null;
  }
  return conversions[normalizedIngredient];
}

List<String> _validAssignmentIds(
  List<String> assignmentIds,
  Set<String> inventoryItemIds,
) {
  return assignmentIds
      .map((itemId) => itemId.trim())
      .where((itemId) => itemId.isNotEmpty && inventoryItemIds.contains(itemId))
      .toList(growable: false);
}

bool _containsNormalizedIngredient(
  List<String> ingredients,
  String ingredient,
) {
  final normalizedIngredient = ingredient.trim();
  if (normalizedIngredient.isEmpty) {
    return false;
  }

  for (final entry in ingredients) {
    if (entry.trim() == normalizedIngredient) {
      return true;
    }
  }
  return false;
}

Map<String, RecipeIngredientAmountConversion> effectiveAssignmentConversions({
  required PreparedMeal template,
  required Map<String, RecipeIngredientAmountConversion>?
  draftAssignmentConversions,
  required Map<String, List<String>> recipeIngredientAssignments,
  required List<InventoryItem> inventoryItems,
  required TemplateIngredientParser ingredientParser,
}) {
  final conversions = draftAssignmentConversions == null
      ? _normalizedAssignmentConversions(
          template.recipeIngredientAmountConversions,
        )
      : _normalizedAssignmentConversions(draftAssignmentConversions);
  if (conversions.isEmpty) {
    return const <String, RecipeIngredientAmountConversion>{};
  }

  final inventoryItemsById = <String, InventoryItem>{
    for (final item in inventoryItems) item.id.trim(): item,
  };
  final nextConversions = <String, RecipeIngredientAmountConversion>{};

  for (final ingredient in template.recipeIngredients) {
    final normalizedIngredient = ingredient.trim();
    if (normalizedIngredient.isEmpty) {
      continue;
    }

    final conversion = _assignmentConversionForIngredient(
      conversions,
      ingredient,
    );
    if (conversion == null) {
      continue;
    }

    final assignmentIds = _assignmentIdsForIngredient(
      recipeIngredientAssignments,
      ingredient,
    );
    if (assignmentIds.isEmpty) {
      continue;
    }

    final assignedItems = assignmentIds
        .map((itemId) => inventoryItemsById[itemId.trim()])
        .whereType<InventoryItem>()
        .toList(growable: false);
    final requirement = ingredientParser.parseRequirement(
      ingredient: ingredient,
      selectedPortions: 1,
      basePortions: 1,
    );
    if (requirement == null) {
      continue;
    }

    final effectiveRequirement = resolveEffectiveRequirementForItems(
      requirement: requirement,
      assignedItems: assignedItems,
      amountConversion: conversion,
    );
    if (effectiveRequirement == null ||
        effectiveRequirement.unit == InventoryAmountUnit.piece) {
      continue;
    }

    nextConversions[normalizedIngredient] = conversion;
  }

  return nextConversions;
}

String _scaledComponentAmount({
  required PreparedMealComponent component,
  required int selectedPortions,
  required int basePortions,
}) {
  if (basePortions <= 0) {
    return '${component.usedAmount} ${component.usedUnit.code}';
  }

  final scaledAmount = component.usedAmount * selectedPortions / basePortions;
  return '${_formatAmount(scaledAmount)} ${component.usedUnit.code}';
}

String _formatAmount(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String inventoryAmountLabel(InventoryItem item) {
  if (item.usesAmountProgress && item.amountUnit != null) {
    return '${item.currentAmount} ${item.amountUnit!.code}';
  }
  return '${item.quantity}x';
}

String _shoppingListLabel(IngredientRowData row) {
  if (row.amountLabel == '-') {
    return row.name;
  }
  return '${row.amountLabel} ${row.name}';
}

String? shoppingListLabelForRow({
  required IngredientRowData row,
  required List<InventoryItem> inventoryItems,
}) {
  if (row.isIgnored) {
    return null;
  }
  if (row.rawIngredient == null || row.requirement == null) {
    return _shoppingListLabel(row);
  }

  final assignedItems = resolveInventoryItemsById(
    inventoryItemIds: row.assignedInventoryItemIds,
    inventoryItems: inventoryItems,
  );
  if (assignedItems.isEmpty) {
    return _shoppingListLabel(row);
  }

  final effectiveRequirement = resolveEffectiveRequirementForItems(
    requirement: row.requirement!,
    assignedItems: assignedItems,
    amountConversion: row.amountConversion,
  );
  if (effectiveRequirement == null) {
    return _shoppingListLabel(row);
  }

  final remainingAmount = _remainingShoppingListAmount(
    assignedItems: assignedItems,
    effectiveRequirement: effectiveRequirement,
  );
  if (remainingAmount < 1) {
    return null;
  }

  return _formattedShoppingListRemainingLabel(
    row: row,
    amount: remainingAmount,
    unit: effectiveRequirement.unit,
    name: effectiveRequirement.name,
  );
}

int _remainingShoppingListAmount({
  required List<InventoryItem> assignedItems,
  required RecipeIngredientEffectiveRequirement effectiveRequirement,
}) {
  var remainingAmount = effectiveRequirement.amount;
  for (final item in assignedItems) {
    if (remainingAmount < 1) {
      break;
    }

    final availableAmount = _availableShoppingListAmount(
      item: item,
      requiredUnit: effectiveRequirement.unit,
    );
    if (availableAmount < 1) {
      continue;
    }

    remainingAmount -= remainingAmount < availableAmount
        ? remainingAmount
        : availableAmount;
  }

  return remainingAmount > 0 ? remainingAmount : 0;
}

int _availableShoppingListAmount({
  required InventoryItem item,
  required InventoryAmountUnit requiredUnit,
}) {
  if (requiredUnit == InventoryAmountUnit.piece) {
    return item.quantity > 0 ? item.quantity : 0;
  }
  if (!item.usesAmountProgress || item.amountUnit != requiredUnit) {
    return 0;
  }
  return item.currentAmount > 0 ? item.currentAmount : 0;
}

String _formattedShoppingListRemainingLabel({
  required IngredientRowData row,
  required int amount,
  required InventoryAmountUnit unit,
  required String name,
}) {
  final countMeasureLabel = row.requirement?.countMeasureLabel?.trim();
  if (unit == InventoryAmountUnit.piece &&
      countMeasureLabel != null &&
      countMeasureLabel.isNotEmpty) {
    return '$amount $countMeasureLabel $name';
  }
  return '$amount ${unit.code} $name';
}

IngredientCardState ingredientCardState({
  required IngredientRowData row,
  required List<InventoryItem> assignedItems,
  required bool hasCompatibleAssignment,
}) {
  if (row.isIgnored) {
    return IngredientCardState.ignored;
  }
  if (row.rawIngredient == null) {
    return IngredientCardState.plain;
  }
  if (assignedItems.isNotEmpty && hasCompatibleAssignment) {
    return IngredientCardState.matched;
  }
  return IngredientCardState.missing;
}

String ingredientDisplayTitle(IngredientRowData row) {
  if (row.amountLabel == '-') {
    return row.name;
  }
  return '${row.amountLabel} ${row.name}';
}

String conversionSourceUnitLabel({
  required TemplateIngredientRequirement? requirement,
  required AppLocalizations l10n,
}) {
  final countMeasureLabel = requirement?.countMeasureLabel?.trim();
  if (countMeasureLabel != null && countMeasureLabel.isNotEmpty) {
    return countMeasureLabel;
  }
  if (requirement?.unit == TemplateIngredientUnit.piece) {
    return l10n.inventoryUnitPiece;
  }
  return requirement?.unit.code ?? l10n.inventoryUnitPiece;
}

String assignedInventoryLabel({
  required AppLocalizations l10n,
  required List<InventoryItem> assignedItems,
}) {
  if (assignedItems.isEmpty) {
    return '';
  }

  if (assignedItems.length == 1) {
    final item = assignedItems.first;
    return '${item.name} - ${inventoryAmountLabel(item)}';
  }

  return l10n.preparedMealTemplateDetailAssignedCount(assignedItems.length);
}

String? resolvePreviewImageUrl({
  required List<InventoryItem> assignedItems,
  required List<InventoryItem> suggestions,
}) {
  if (assignedItems.isNotEmpty) {
    return assignedItems.first.imageUrl;
  }
  if (suggestions.isNotEmpty) {
    return suggestions.first.imageUrl;
  }
  return null;
}

String createMealFailureMessage(
  AppLocalizations l10n,
  PreparedMealCreationFailureReason? failureReason,
) {
  return switch (failureReason) {
    PreparedMealCreationFailureReason.invalidInput =>
      l10n.preparedMealTemplateDetailInvalidMealMessage,
    PreparedMealCreationFailureReason.itemUnavailable =>
      l10n.preparedMealItemUnavailableMessage,
    PreparedMealCreationFailureReason.insufficientAmount =>
      l10n.preparedMealInsufficientAmountMessage,
    PreparedMealCreationFailureReason.missingNutrition =>
      l10n.preparedMealMissingNutritionMessage,
    PreparedMealCreationFailureReason.inventorySaveFailed ||
    PreparedMealCreationFailureReason.mealSaveFailed ||
    null => l10n.preparedMealActionFailed,
  };
}
