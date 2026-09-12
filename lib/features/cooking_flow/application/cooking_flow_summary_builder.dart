import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_amount_utils.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_requirement.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_ingredient_parser.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

export 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_ingredient_parser.dart';

/// Normalized amount requirement.
typedef CookingFlowIngredientRequirement = CookingFlowInventoryRequirement;

/// Parses amount labels into normalized requirements.
CookingFlowIngredientRequirement? parseCookingFlowIngredientRequirement(
  String value, {
  String? localeCode,
}) {
  return cookingFlowParseInventoryRequirement(value, localeCode: localeCode);
}

List<InventoryItem> _resolveSelectedInventoryItems({
  required List<CookingFlowIntroSelectionDraft> selections,
  required List<InventoryItem> inventoryItems,
  required bool includeAdditionalIngredients,
}) {
  final inventoryById = <String, InventoryItem>{
    for (final item in inventoryItems) item.id: item,
  };
  return selections
      .where(
        (selection) =>
            includeAdditionalIngredients || !selection.isAdditionalIngredient,
      )
      .map((selection) => inventoryById[selection.itemId])
      .whereType<InventoryItem>()
      .toList(growable: false);
}

double _availableAmount({
  required List<InventoryItem> selectedItems,
  required CookingFlowIngredientRequirement requirement,
}) {
  return cookingFlowAvailableInventoryAmount(
    selectedItems: selectedItems,
    requirement: requirement,
  );
}

/// Parses whole-number weight text.
int parseCookingFlowWholeWeight(String value) {
  return parseCookingFlowQuantity(value)?.round() ?? 0;
}

/// Builds stable signature used to detect summary source changes.
String buildCookingFlowSummarySourceSignature(
  CookingFlowIntroDraft? draft, {
  required int targetPortions,
}) {
  final buffer = StringBuffer('portions:')
    ..write(targetPortions)
    ..write(';');
  for (final rowState
      in draft?.rowStates ?? const <CookingFlowIntroRowDraft>[]) {
    buffer
      ..write(rowState.rawIngredient)
      ..write('|')
      ..write(rowState.action?.name ?? '')
      ..write('|')
      ..write(rowState.conflictResolution?.name ?? '');
    for (final selection in rowState.selections) {
      buffer
        ..write('|')
        ..write(selection.itemId)
        ..write(':')
        ..write(selection.isAdditionalIngredient ? '1' : '0');
    }
    buffer.write(';');
  }
  return buffer.toString();
}

/// Prepares summary rows from intro selections.
List<CookingFlowSummaryIngredientDraft> prepareCookingFlowSummaryIngredients({
  required PreparedMeal template,
  required List<InventoryItem> inventoryItems,
  required CookingFlowIntroDraft? introDraft,
  required int targetPortions,
  required List<CookingFlowSummaryIngredientDraft> currentSummaryIngredients,
}) {
  final freshRows = buildCookingFlowSummaryIngredientsFromIntro(
    template: template,
    inventoryItems: inventoryItems,
    introDraft: introDraft,
    targetPortions: targetPortions,
  );
  if (currentSummaryIngredients.isEmpty) {
    return freshRows;
  }

  final existingByKey = <String, CookingFlowSummaryIngredientDraft>{
    for (final row in currentSummaryIngredients) row.key: row,
  };
  final freshKeys = freshRows.map((row) => row.key).toSet();
  final mergedFreshRows = freshRows
      .map((row) {
        final existing = existingByKey[row.key];
        if (existing == null) {
          return row;
        }
        return row.copyWith(amount: existing.amount);
      })
      .toList(growable: false);
  final preservedAdditionalRows = currentSummaryIngredients.where((row) {
    return row.kind == CookingFlowSummaryIngredientKind.additional &&
        !freshKeys.contains(row.key);
  });
  return <CookingFlowSummaryIngredientDraft>[
    ...mergedFreshRows,
    ...preservedAdditionalRows,
  ];
}

/// Builds summary rows from intro selections.
List<CookingFlowSummaryIngredientDraft>
buildCookingFlowSummaryIngredientsFromIntro({
  required PreparedMeal template,
  required List<InventoryItem> inventoryItems,
  required CookingFlowIntroDraft? introDraft,
  required int targetPortions,
  String? localeCode,
}) {
  final draftByIngredient = <String, CookingFlowIntroRowDraft>{
    for (final rowState
        in introDraft?.rowStates ?? const <CookingFlowIntroRowDraft>[])
      rowState.rawIngredient: rowState,
  };
  final rows = <CookingFlowSummaryIngredientDraft>[];

  for (final rawIngredient in template.recipeIngredients) {
    final rowDraft = draftByIngredient[rawIngredient];
    if (rowDraft?.action != CookingFlowIntroRowAction.assigned) {
      continue;
    }

    final hasEditedIngredient =
        rowDraft?.editedName?.isNotEmpty == true ||
        rowDraft?.editedAmountLabel?.isNotEmpty == true;
    final parsedIngredient = hasEditedIngredient
        ? CookingFlowParsedIngredient(
            amountLabel: rowDraft!.editedAmountLabel?.trim() ?? '',
            name: rowDraft.editedName?.trim() ?? rawIngredient.trim(),
          )
        : parseCookingFlowIngredient(
            rawIngredient,
            selectedPortions: targetPortions,
            basePortions: template.totalPortions,
            localeCode: localeCode,
          );
    final requirement = parsedIngredient == null
        ? null
        : parseCookingFlowIngredientRequirement(
            parsedIngredient.amountLabel,
            localeCode: localeCode,
          );
    final baseSelections = rowDraft!.selections
        .where((selection) => !selection.isAdditionalIngredient)
        .toList(growable: false);
    final baseItems = _resolveSelectedInventoryItems(
      selections: baseSelections,
      inventoryItems: inventoryItems,
      includeAdditionalIngredients: false,
    );
    if (baseItems.isNotEmpty && parsedIngredient != null) {
      final effectiveAmount =
          rowDraft.conflictResolution ==
                  CookingFlowIntroConflictResolution.adjustTemplate &&
              requirement != null
          ? _availableAmount(
              selectedItems: baseItems,
              requirement: requirement,
            )
          : rowDraft.conflictResolution ==
                CookingFlowIntroConflictResolution.weighLater
          ? 0
          : requirement?.amount;
      rows.add(
        CookingFlowSummaryIngredientDraft(
          key: 'template:$rawIngredient',
          name: parsedIngredient.name,
          amount: formatCookingFlowDecimal((effectiveAmount ?? 0).toDouble()),
          unitCode: requirement?.unitCode ?? cookingFlowPieceUnitCode,
          inventoryItemIds: baseItems
              .map((item) => item.id)
              .toList(growable: false),
          kind: CookingFlowSummaryIngredientKind.template,
          sourceIngredient: rawIngredient,
        ),
      );
    }

    for (final selection in rowDraft.selections) {
      if (!selection.isAdditionalIngredient) {
        continue;
      }
      final extraItems = _resolveSelectedInventoryItems(
        selections: <CookingFlowIntroSelectionDraft>[selection],
        inventoryItems: inventoryItems,
        includeAdditionalIngredients: true,
      );
      if (extraItems.isEmpty) {
        continue;
      }
      final extraItem = extraItems.first;
      rows.add(
        CookingFlowSummaryIngredientDraft(
          key: 'additional:$rawIngredient:${extraItem.id}',
          name: extraItem.name,
          amount: defaultCookingFlowSummaryAmountForItem(extraItem).toString(),
          unitCode: cookingFlowSummaryUnitCodeForItem(extraItem),
          inventoryItemIds: <String>[extraItem.id],
          kind: CookingFlowSummaryIngredientKind.additional,
        ),
      );
    }
  }

  return rows;
}

/// Summary row unit for inventory item.
String cookingFlowSummaryUnitCodeForItem(InventoryItem item) {
  if (item.usesAmountProgress && item.amountUnit != null) {
    return item.amountUnit!.code;
  }
  return cookingFlowPieceUnitCode;
}

/// Default summary amount for inventory item.
int defaultCookingFlowSummaryAmountForItem(InventoryItem item) {
  if (item.usesAmountProgress && item.amountUnit != null) {
    return item.currentAmount;
  }
  return item.quantity;
}

/// Formats summary row back into template ingredient text.
String formatCookingFlowSummaryIngredient(
  CookingFlowSummaryIngredientDraft row,
) {
  final trimmedAmount = row.amount.trim();
  final trimmedName = row.name.trim();
  if (trimmedAmount.isEmpty) {
    return trimmedName;
  }
  if (row.unitCode == cookingFlowPieceUnitCode) {
    return '$trimmedAmount pc $trimmedName'.trim();
  }
  return '$trimmedAmount${row.unitCode} $trimmedName'.trim();
}

/// Parses entered summary amount.
int parseCookingFlowSummaryUsedAmount(String value) {
  return parseCookingFlowQuantity(value)?.round() ?? 0;
}
