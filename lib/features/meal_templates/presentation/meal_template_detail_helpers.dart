part of 'meal_template_detail_page.dart';

class _IngredientRowData {
  const _IngredientRowData({
    required this.name,
    required this.amountLabel,
    this.rawIngredient,
    this.isIgnored = false,
    this.assignedInventoryItemIds = const <String>[],
  });

  final String name;
  final String amountLabel;
  final String? rawIngredient;
  final bool isIgnored;
  final List<String> assignedInventoryItemIds;
}

PreparedMeal? _findTemplate({
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

int _defaultPortions(int totalPortions) {
  return totalPortions > 0 ? totalPortions : 1;
}

Map<String, List<String>> _effectiveAssignments({
  required PreparedMeal template,
  required Map<String, List<String>>? draftAssignments,
}) {
  if (draftAssignments == null) {
    return _normalizedAssignments(template.recipeIngredientAssignments);
  }
  return _normalizedAssignments(draftAssignments);
}

Map<String, List<String>> _updatedAssignments({
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

bool _assignmentMapsEqual(
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

List<_IngredientRowData> _buildIngredientRows({
  required PreparedMeal template,
  required Map<String, List<String>> recipeIngredientAssignments,
  required int selectedPortions,
}) {
  if (template.components.isNotEmpty) {
    return template.components
        .map(
          (component) => _IngredientRowData(
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
      .map(
        (ingredient) => _scaledRecipeIngredient(
          ingredient,
          isIgnored: template.ignoredRecipeIngredients.contains(ingredient),
          assignedInventoryItemIds:
              recipeIngredientAssignments[ingredient] ?? const <String>[],
          selectedPortions: selectedPortions,
          basePortions: template.totalPortions,
        ),
      )
      .toList(growable: false);
}

_IngredientRowData _scaledRecipeIngredient(
  String ingredient, {
  required bool isIgnored,
  required List<String> assignedInventoryItemIds,
  required int selectedPortions,
  required int basePortions,
}) {
  final trimmed = ingredient.trim();
  final match = RegExp(
    r'^(\d+(?:[.,]\d+)?)\s+(\S+)\s+(.+)$',
  ).firstMatch(trimmed);
  if (match == null) {
    return _IngredientRowData(
      name: trimmed,
      amountLabel: '-',
      rawIngredient: ingredient,
      isIgnored: isIgnored,
      assignedInventoryItemIds: assignedInventoryItemIds,
    );
  }

  final rawQuantity = match.group(1);
  final unit = match.group(2);
  final name = match.group(3);
  if (rawQuantity == null || unit == null || name == null) {
    return _IngredientRowData(
      name: trimmed,
      amountLabel: '-',
      rawIngredient: ingredient,
      isIgnored: isIgnored,
      assignedInventoryItemIds: assignedInventoryItemIds,
    );
  }

  final parsedQuantity = double.tryParse(rawQuantity.replaceAll(',', '.'));
  if (parsedQuantity == null || basePortions <= 0) {
    return _IngredientRowData(
      name: name,
      amountLabel: '$rawQuantity $unit',
      rawIngredient: ingredient,
      isIgnored: isIgnored,
      assignedInventoryItemIds: assignedInventoryItemIds,
    );
  }

  final scaledQuantity = parsedQuantity * selectedPortions / basePortions;
  return _IngredientRowData(
    name: name,
    amountLabel: '${_formatAmount(scaledQuantity)} $unit',
    rawIngredient: ingredient,
    isIgnored: isIgnored,
    assignedInventoryItemIds: assignedInventoryItemIds,
  );
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

String _inventoryAmountLabel(InventoryItem item) {
  if (item.usesAmountProgress && item.amountUnit != null) {
    return '${item.currentAmount} ${item.amountUnit!.code}';
  }
  return '${item.quantity}x';
}

String _shoppingListLabel(_IngredientRowData row) {
  if (row.amountLabel == '-') {
    return row.name;
  }
  return '${row.amountLabel} ${row.name}';
}

String _buildIngredientSubtitle({
  required AppLocalizations l10n,
  required _IngredientRowData row,
  required List<InventoryItem> assignedItems,
}) {
  if (row.isIgnored) {
    return l10n.preparedMealTemplateDetailIgnoredAmount(row.amountLabel);
  }
  if (assignedItems.isNotEmpty) {
    final assignedLabel = assignedItems.length == 1
        ? assignedItems.first.name
        : l10n.preparedMealTemplateDetailAssignedCount(assignedItems.length);
    return '$assignedLabel • ${row.amountLabel}';
  }
  return row.amountLabel;
}

String? _resolvePreviewImageUrl({
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

String _createMealFailureMessage(
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
