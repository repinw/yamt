import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_inventory_requirements.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_parser.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

export 'cooking_flow_instruction_inventory_requirements.dart';

/// Resolved ingredient reference with display labels and search terms.
class CookingIngredientReference {
  /// Creates an ingredient reference.
  const CookingIngredientReference({
    required this.rawIngredient,
    required this.name,
    required this.displayAmountLabel,
    required this.parserLocale,
  });

  /// Raw ingredient string from recipe or component.
  final String rawIngredient;

  /// Cleaned or edited ingredient name.
  final String name;

  /// Display label for the amount to show in instructions.
  final String displayAmountLabel;

  /// Parser locale for morphological resolution.
  final CookingFlowParserLocale parserLocale;

  /// Candidate search patterns and variants for this ingredient.
  List<String> get matchTexts {
    final seen = <String>{};
    final variants = <String>[];

    void addCandidate(String? text) {
      if (text == null) return;
      final trimmed = text.trim();
      if (trimmed.isEmpty) return;
      if (seen.add(trimmed.toLowerCase())) {
        variants.add(trimmed);
      }
    }

    final startsWithAmount = RegExp(r'^\d').hasMatch(rawIngredient.trim());
    if (!startsWithAmount) {
      addCandidate(rawIngredient);
    }
    addCandidate(name);

    final cleanedName = cleanIngredientReferenceName(name);
    addCandidate(cleanedName);

    parserLocale.resolveIngredientVariants(cleanedName).forEach(addCandidate);
    if (cleanedName != name) {
      parserLocale.resolveIngredientVariants(name).forEach(addCandidate);
    }

    return variants;
  }

  /// Longest character length among [matchTexts].
  int get longestMatchTextLength {
    return matchTexts.fold<int>(0, (longest, text) {
      return text.length > longest ? text.length : longest;
    });
  }
}

/// Builds ingredient references by combining template components, ingredients,
/// and user overrides from [introDraft].
List<CookingIngredientReference> buildCookingIngredientReferences({
  required PreparedMeal template,
  required CookingFlowIntroDraft? introDraft,
  required List<InventoryItem> inventoryItems,
  required CookingFlowInstructionText text,
  required String localeCode,
}) {
  final parserLocale = CookingFlowParserLocale.forLocaleCode(localeCode);
  final pieceUnitLabel = text.pieceUnit.trim().isNotEmpty
      ? text.pieceUnit.trim()
      : parserLocale.defaultPieceUnitLabel;
  final introRows = <String, CookingFlowIntroRowDraft>{
    for (final row
        in introDraft?.rowStates ?? const <CookingFlowIntroRowDraft>[])
      row.rawIngredient: row,
  };

  final rows = template.components.isNotEmpty
      ? _componentsToIngredientRows(template.components, pieceUnitLabel)
      : _recipeIngredientsToIngredientRows(
          template.recipeIngredients,
          text,
          parserLocale,
          pieceUnitLabel,
        );

  return rows
      .map((row) {
        final rowDraft = introRows[row.rawIngredient];
        final displayAmountLabel = _resolveCookingIngredientAmountLabel(
          row: row,
          rowDraft: rowDraft,
          inventoryItems: inventoryItems,
          parserLocale: parserLocale,
          pieceUnitLabel: pieceUnitLabel,
        );
        final effectiveName = rowDraft?.editedName?.trim().isNotEmpty == true
            ? rowDraft!.editedName!.trim()
            : row.name;
        return CookingIngredientReference(
          rawIngredient: row.rawIngredient,
          name: effectiveName,
          displayAmountLabel: displayAmountLabel,
          parserLocale: parserLocale,
        );
      })
      .toList(growable: false);
}

List<CookingIngredientRowData> _componentsToIngredientRows(
  List<PreparedMealComponent> components,
  String pieceUnitLabel,
) {
  return components
      .map(
        (component) => CookingIngredientRowData(
          rawIngredient:
              '${component.usedAmount}${component.usedUnit.code} '
              '${component.name}',
          name: component.name,
          amountLabel: component.usedUnit == InventoryAmountUnit.piece
              ? '${component.usedAmount} $pieceUnitLabel'
              : '${component.usedAmount}${component.usedUnit.code}',
        ),
      )
      .toList(growable: false);
}

List<CookingIngredientRowData> _recipeIngredientsToIngredientRows(
  List<String> ingredients,
  CookingFlowInstructionText text,
  CookingFlowParserLocale parserLocale,
  String pieceUnitLabel,
) {
  return ingredients
      .map(
        (ingredient) => parseRecipeIngredientRow(
          ingredient: ingredient,
          text: text,
          parserLocale: parserLocale,
          pieceUnitLabel: pieceUnitLabel,
        ),
      )
      .toList(growable: false);
}

String _resolveCookingIngredientAmountLabel({
  required CookingIngredientRowData row,
  required CookingFlowIntroRowDraft? rowDraft,
  required List<InventoryItem> inventoryItems,
  required CookingFlowParserLocale parserLocale,
  required String pieceUnitLabel,
}) {
  if (rowDraft?.editedAmountLabel?.trim().isNotEmpty == true) {
    return rowDraft!.editedAmountLabel!.trim();
  }

  if (rowDraft == null ||
      rowDraft.action != CookingFlowIntroRowAction.assigned) {
    return row.amountLabel;
  }

  final requirement = parseCookingInventoryRequirement(
    row.amountLabel,
    parserLocale,
  );
  final inventoryById = <String, InventoryItem>{
    for (final item in inventoryItems) item.id: item,
  };
  final selectedItems = rowDraft.selections
      .where((selection) => !selection.isAdditionalIngredient)
      .map((selection) => inventoryById[selection.itemId])
      .whereType<InventoryItem>()
      .toList(growable: false);
  if (selectedItems.isEmpty) {
    return row.amountLabel;
  }

  final selectedAmount = selectedCookingInventoryAmount(
    selectedItems: selectedItems,
    pieceUnitLabel: pieceUnitLabel,
  );
  if (selectedAmount != null &&
      shouldUseSelectedCookingAmount(
        requirement: requirement,
        selectedAmount: selectedAmount,
      )) {
    return selectedAmount.label;
  }

  if (rowDraft.conflictResolution !=
          CookingFlowIntroConflictResolution.adjustTemplate ||
      requirement == null) {
    return row.amountLabel;
  }

  final availableAmount = availableCookingInventoryAmount(
    selectedItems: selectedItems,
    requirement: requirement,
  );
  return formatCookingInventoryRequirementAmount(
    amount: availableAmount,
    unitCode: requirement.unitCode,
    pieceUnitLabel: pieceUnitLabel,
  );
}
