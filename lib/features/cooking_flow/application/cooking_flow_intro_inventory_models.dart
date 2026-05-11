import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Piece unit code used by cookflow inventory parsing.
const String cookingFlowPieceUnitCode = cookingFlowParserPieceUnitCode;

/// User-selected inventory item for an ingredient row.
class CookingFlowInventoryAssignmentSelection {
  /// Creates assignment selection.
  const CookingFlowInventoryAssignmentSelection({
    required this.itemId,
    this.isAdditionalIngredient = false,
  });

  /// Inventory item id.
  final String itemId;

  /// Whether this item was added as an extra ingredient.
  final bool isAdditionalIngredient;
}

/// User action for one intro ingredient row.
enum CookingFlowInventoryRowAction {
  /// Row is assigned to inventory.
  assigned,

  /// Row should be added to shopping list.
  shoppingCart,

  /// Row is ignored for this flow.
  ignored,
}

/// Conflict resolution picked by user.
enum CookingFlowInventoryConflictResolution {
  /// Buy missing inventory amount.
  buyRemaining,

  /// Reduce recipe amount to available inventory.
  adjustTemplate,

  /// Weigh real amount later.
  weighLater,
}

/// Intro row parsed for inventory assignment.
class CookingFlowInventoryCheckRowData {
  /// Creates intro inventory row data.
  const CookingFlowInventoryCheckRowData({
    required this.rawIngredient,
    required this.name,
    required this.amountLabel,
    this.isEdited = false,
    this.imageUrl,
  });

  /// Original recipe ingredient text.
  final String rawIngredient;

  /// Ingredient name.
  final String name;

  /// Ingredient amount label.
  final String amountLabel;

  /// Whether user edited this row.
  final bool isEdited;

  /// Optional preview image URL.
  final String? imageUrl;

  /// Returns updated row.
  CookingFlowInventoryCheckRowData copyWith({
    String? name,
    String? amountLabel,
    bool? isEdited,
  }) {
    return CookingFlowInventoryCheckRowData(
      rawIngredient: rawIngredient,
      name: name ?? this.name,
      amountLabel: amountLabel ?? this.amountLabel,
      isEdited: isEdited ?? this.isEdited,
      imageUrl: imageUrl,
    );
  }
}

/// Formats inventory item amount for assignment UI.
String cookingFlowInventoryAmountLabel(InventoryItem item) {
  if (item.usesAmountProgress && item.amountUnit != null) {
    return '${item.currentAmount} ${item.amountUnit!.code}';
  }
  return '${item.quantity}x';
}

/// Maps persisted selection draft into UI/application selection.
CookingFlowInventoryAssignmentSelection cookingFlowInventoryAssignmentSelection(
  CookingFlowIntroSelectionDraft selection,
) {
  return CookingFlowInventoryAssignmentSelection(
    itemId: selection.itemId,
    isAdditionalIngredient: selection.isAdditionalIngredient,
  );
}

/// Maps UI/application selection into persisted selection draft.
CookingFlowIntroSelectionDraft cookingFlowSessionIntroSelectionDraft(
  CookingFlowInventoryAssignmentSelection selection,
) {
  return CookingFlowIntroSelectionDraft(
    itemId: selection.itemId,
    isAdditionalIngredient: selection.isAdditionalIngredient,
  );
}

/// Maps persisted row action into UI/application row action.
CookingFlowInventoryRowAction? cookingFlowInventoryRowAction(
  CookingFlowIntroRowAction? action,
) {
  return switch (action) {
    CookingFlowIntroRowAction.assigned =>
      CookingFlowInventoryRowAction.assigned,
    CookingFlowIntroRowAction.shoppingCart =>
      CookingFlowInventoryRowAction.shoppingCart,
    CookingFlowIntroRowAction.ignored => CookingFlowInventoryRowAction.ignored,
    null => null,
  };
}

/// Maps UI/application row action into persisted row action.
CookingFlowIntroRowAction? cookingFlowSessionIntroRowAction(
  CookingFlowInventoryRowAction? action,
) {
  return switch (action) {
    CookingFlowInventoryRowAction.assigned =>
      CookingFlowIntroRowAction.assigned,
    CookingFlowInventoryRowAction.shoppingCart =>
      CookingFlowIntroRowAction.shoppingCart,
    CookingFlowInventoryRowAction.ignored => CookingFlowIntroRowAction.ignored,
    null => null,
  };
}

/// Maps persisted conflict resolution into UI/application resolution.
CookingFlowInventoryConflictResolution? cookingFlowInventoryConflictResolution(
  CookingFlowIntroConflictResolution? resolution,
) {
  return switch (resolution) {
    CookingFlowIntroConflictResolution.buyRemaining =>
      CookingFlowInventoryConflictResolution.buyRemaining,
    CookingFlowIntroConflictResolution.adjustTemplate =>
      CookingFlowInventoryConflictResolution.adjustTemplate,
    CookingFlowIntroConflictResolution.weighLater =>
      CookingFlowInventoryConflictResolution.weighLater,
    null => null,
  };
}

/// Maps UI/application conflict resolution into persisted resolution.
CookingFlowIntroConflictResolution? cookingFlowSessionConflictResolution(
  CookingFlowInventoryConflictResolution? resolution,
) {
  return switch (resolution) {
    CookingFlowInventoryConflictResolution.buyRemaining =>
      CookingFlowIntroConflictResolution.buyRemaining,
    CookingFlowInventoryConflictResolution.adjustTemplate =>
      CookingFlowIntroConflictResolution.adjustTemplate,
    CookingFlowInventoryConflictResolution.weighLater =>
      CookingFlowIntroConflictResolution.weighLater,
    null => null,
  };
}

/// Splits amount and unit labels.
({String amount, String unit}) cookingFlowSplitIngredientAmountLabel(
  String value,
) {
  final trimmed = cookingFlowStripInventoryPackageCountPrefix(value);
  final match = RegExp(
    r'^(\d+(?:[.,]\d+)?)(?:\s*([a-zA-ZäöüÄÖÜß]+))?$',
  ).firstMatch(trimmed);
  if (match == null) {
    return (amount: trimmed, unit: '');
  }
  return (
    amount: match.group(1)?.trim() ?? trimmed,
    unit: match.group(2)?.trim() ?? '',
  );
}

/// Builds shopping list label for an ingredient row.
String cookingFlowShoppingListLabelForRow(
  CookingFlowInventoryCheckRowData row,
) {
  final trimmedAmount = row.amountLabel.trim();
  if (trimmedAmount.isEmpty) {
    return row.name;
  }
  return '$trimmedAmount ${row.name}';
}

/// Removes package count prefix, for example `2x`.
String cookingFlowStripInventoryPackageCountPrefix(String value) {
  final trimmed = value.trim();
  final match = RegExp(
    r'^\d+(?:[.,]\d+)?\s*x\s*(.+)$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  return match?.group(1)?.trim() ?? trimmed;
}

/// Returns locale-specific amount unit regex alternation.
String cookingFlowKnownAmountUnitsPatternForLocale(String? localeCode) {
  return CookingFlowParserLocale.forLocaleCode(localeCode).amountUnitPattern;
}

/// Combined amount unit regex alternation.
final String cookingFlowKnownAmountUnitsPattern =
    CookingFlowParserLocale.allSupported.amountUnitPattern;
