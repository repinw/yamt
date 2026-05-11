// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_flow_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CookingFlowIntroSelectionDraft _$CookingFlowIntroSelectionDraftFromJson(
  Map<String, dynamic> json,
) => CookingFlowIntroSelectionDraft(
  itemId: json['item_id'] as String,
  isAdditionalIngredient: json['is_additional_ingredient'] as bool? ?? false,
);

Map<String, dynamic> _$CookingFlowIntroSelectionDraftToJson(
  CookingFlowIntroSelectionDraft instance,
) => <String, dynamic>{
  'item_id': instance.itemId,
  'is_additional_ingredient': instance.isAdditionalIngredient,
};

CookingFlowIntroRowDraft _$CookingFlowIntroRowDraftFromJson(
  Map<String, dynamic> json,
) => CookingFlowIntroRowDraft(
  rawIngredient: json['raw_ingredient'] as String,
  action: $enumDecodeNullable(
    _$CookingFlowIntroRowActionEnumMap,
    json['action'],
  ),
  selections:
      (json['selections'] as List<dynamic>?)
          ?.map(
            (e) => CookingFlowIntroSelectionDraft.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList() ??
      const <CookingFlowIntroSelectionDraft>[],
  conflictResolution: $enumDecodeNullable(
    _$CookingFlowIntroConflictResolutionEnumMap,
    json['conflict_resolution'],
  ),
  editedName: json['edited_name'] as String?,
  editedAmountLabel: json['edited_amount_label'] as String?,
);

Map<String, dynamic> _$CookingFlowIntroRowDraftToJson(
  CookingFlowIntroRowDraft instance,
) => <String, dynamic>{
  'raw_ingredient': instance.rawIngredient,
  'action': _$CookingFlowIntroRowActionEnumMap[instance.action],
  'selections': instance.selections.map((e) => e.toJson()).toList(),
  'conflict_resolution':
      _$CookingFlowIntroConflictResolutionEnumMap[instance.conflictResolution],
  'edited_name': instance.editedName,
  'edited_amount_label': instance.editedAmountLabel,
};

const _$CookingFlowIntroRowActionEnumMap = {
  CookingFlowIntroRowAction.assigned: 'assigned',
  CookingFlowIntroRowAction.shoppingCart: 'shoppingCart',
  CookingFlowIntroRowAction.ignored: 'ignored',
};

const _$CookingFlowIntroConflictResolutionEnumMap = {
  CookingFlowIntroConflictResolution.buyRemaining: 'buyRemaining',
  CookingFlowIntroConflictResolution.adjustTemplate: 'adjustTemplate',
  CookingFlowIntroConflictResolution.weighLater: 'weighLater',
};

CookingFlowIntroDraft _$CookingFlowIntroDraftFromJson(
  Map<String, dynamic> json,
) => CookingFlowIntroDraft(
  rowStates:
      (json['row_states'] as List<dynamic>?)
          ?.map(
            (e) => CookingFlowIntroRowDraft.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <CookingFlowIntroRowDraft>[],
);

Map<String, dynamic> _$CookingFlowIntroDraftToJson(
  CookingFlowIntroDraft instance,
) => <String, dynamic>{
  'row_states': instance.rowStates.map((e) => e.toJson()).toList(),
};

CookingFlowSummaryIngredientSessionDraft
_$CookingFlowSummaryIngredientSessionDraftFromJson(Map<String, dynamic> json) =>
    CookingFlowSummaryIngredientSessionDraft(
      key: json['key'] as String,
      name: json['name'] as String,
      amount: json['amount'] as String,
      unitCode: json['unit_code'] as String,
      inventoryItemIds: (json['inventory_item_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      kind: $enumDecode(
        _$CookingFlowSummaryIngredientKindEnumMap,
        json['kind'],
      ),
      sourceIngredient: json['source_ingredient'] as String?,
    );

Map<String, dynamic> _$CookingFlowSummaryIngredientSessionDraftToJson(
  CookingFlowSummaryIngredientSessionDraft instance,
) => <String, dynamic>{
  'key': instance.key,
  'name': instance.name,
  'amount': instance.amount,
  'unit_code': instance.unitCode,
  'inventory_item_ids': instance.inventoryItemIds,
  'kind': _$CookingFlowSummaryIngredientKindEnumMap[instance.kind]!,
  'source_ingredient': instance.sourceIngredient,
};

const _$CookingFlowSummaryIngredientKindEnumMap = {
  CookingFlowSummaryIngredientKind.template: 'template',
  CookingFlowSummaryIngredientKind.additional: 'additional',
};

CookingFlowStorageContainerSessionDraft
_$CookingFlowStorageContainerSessionDraftFromJson(Map<String, dynamic> json) =>
    CookingFlowStorageContainerSessionDraft(
      id: json['id'] as String,
      label: json['label'] as String,
      taraText: json['tara_text'] as String,
      grossWeightText: json['gross_weight_text'] as String,
      portionCount: (json['portion_count'] as num).toDouble(),
      taraUtensilId: json['tara_utensil_id'] as String?,
    );

Map<String, dynamic> _$CookingFlowStorageContainerSessionDraftToJson(
  CookingFlowStorageContainerSessionDraft instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'tara_text': instance.taraText,
  'tara_utensil_id': instance.taraUtensilId,
  'gross_weight_text': instance.grossWeightText,
  'portion_count': instance.portionCount,
};

CookingFlowSession _$CookingFlowSessionFromJson(Map<String, dynamic> json) =>
    CookingFlowSession(
      templateId: json['template_id'] as String,
      step: $enumDecode(_$CookingFlowSessionStepEnumMap, json['step']),
      taraText: json['tara_text'] as String,
      adjustmentInputText: json['adjustment_input_text'] as String,
      adjustments: (json['adjustments'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      summaryIngredients: (json['summary_ingredients'] as List<dynamic>)
          .map(
            (e) => CookingFlowSummaryIngredientSessionDraft.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      grossWeightText: json['gross_weight_text'] as String,
      splitIntoPortions: json['split_into_portions'] as bool,
      portionCount: (json['portion_count'] as num).toDouble(),
      introDraft: CookingFlowIntroDraft.fromJson(
        json['intro_draft'] as Map<String, dynamic>,
      ),
      introShoppingHandled: json['intro_shopping_handled'] as bool,
      introShoppingBaselineInventoryItemIds:
          (json['intro_shopping_baseline_inventory_item_ids'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      finalPortionCount: (json['final_portion_count'] as num?)?.toDouble(),
      storageContainers:
          (json['storage_containers'] as List<dynamic>?)
              ?.map(
                (e) => CookingFlowStorageContainerSessionDraft.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const <CookingFlowStorageContainerSessionDraft>[],
      ingredientContainerAssignments:
          (json['ingredient_container_assignments'] as Map<String, dynamic>?)
              ?.map((k, e) => MapEntry(k, e as String)) ??
          const <String, String>{},
      taraUtensilId: json['tara_utensil_id'] as String?,
    );

Map<String, dynamic> _$CookingFlowSessionToJson(
  CookingFlowSession instance,
) => <String, dynamic>{
  'template_id': instance.templateId,
  'step': _$CookingFlowSessionStepEnumMap[instance.step]!,
  'tara_text': instance.taraText,
  'tara_utensil_id': instance.taraUtensilId,
  'adjustment_input_text': instance.adjustmentInputText,
  'adjustments': instance.adjustments,
  'summary_ingredients': instance.summaryIngredients
      .map((e) => e.toJson())
      .toList(),
  'gross_weight_text': instance.grossWeightText,
  'split_into_portions': instance.splitIntoPortions,
  'portion_count': instance.portionCount,
  'final_portion_count': instance.finalPortionCount,
  'intro_draft': instance.introDraft.toJson(),
  'intro_shopping_handled': instance.introShoppingHandled,
  'intro_shopping_baseline_inventory_item_ids':
      instance.introShoppingBaselineInventoryItemIds,
  'storage_containers': instance.storageContainers
      .map((e) => e.toJson())
      .toList(),
  'ingredient_container_assignments': instance.ingredientContainerAssignments,
};

const _$CookingFlowSessionStepEnumMap = {
  CookingFlowSessionStep.start: 'start',
  CookingFlowSessionStep.preparation: 'preparation',
  CookingFlowSessionStep.cooking: 'cooking',
  CookingFlowSessionStep.summary: 'summary',
  CookingFlowSessionStep.finalize: 'finalize',
};
