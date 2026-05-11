import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';

const Object _keepSummaryValue = Object();

/// Editable ingredient draft for summary step.
class CookingFlowSummaryIngredientDraft {
  /// Creates draft.
  const CookingFlowSummaryIngredientDraft({
    required this.key,
    required this.name,
    required this.amount,
    required this.unitCode,
    required this.inventoryItemIds,
    required this.kind,
    this.sourceIngredient,
  });

  /// Stable row key for merge/restore.
  final String key;

  /// Ingredient label.
  final String name;

  /// Editable amount.
  final String amount;

  /// Displayed amount unit.
  final String unitCode;

  /// Bound inventory item ids used for save.
  final List<String> inventoryItemIds;

  /// Row type.
  final CookingFlowSummaryIngredientKind kind;

  /// Original template ingredient text for template rows.
  final String? sourceIngredient;

  /// Returns updated copy.
  CookingFlowSummaryIngredientDraft copyWith({
    String? key,
    String? name,
    String? amount,
    String? unitCode,
    List<String>? inventoryItemIds,
    CookingFlowSummaryIngredientKind? kind,
    Object? sourceIngredient = _keepSummaryValue,
  }) {
    return CookingFlowSummaryIngredientDraft(
      key: key ?? this.key,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unitCode: unitCode ?? this.unitCode,
      inventoryItemIds: inventoryItemIds ?? this.inventoryItemIds,
      kind: kind ?? this.kind,
      sourceIngredient: sourceIngredient == _keepSummaryValue
          ? this.sourceIngredient
          : sourceIngredient as String?,
    );
  }
}
