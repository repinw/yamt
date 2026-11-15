// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_run.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CookRun _$CookRunFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const [
      'id',
      'kind',
      'step',
      'recipe_id',
      'name',
      'image_asset_id',
      'image_url',
      'base_portions',
      'portions',
      'steps',
      'started_by',
      'started_by_name',
      'started_at',
      'lines',
      'pots',
      'with_guide',
      'guide_step',
      'timers',
      'meals',
      'to_cookbook',
      'dropped_item_ids',
    ],
    requiredKeys: const [
      'id',
      'kind',
      'step',
      'recipe_id',
      'name',
      'image_asset_id',
      'image_url',
      'base_portions',
      'portions',
      'steps',
      'started_by',
      'started_by_name',
      'started_at',
      'lines',
      'pots',
      'with_guide',
      'guide_step',
      'timers',
      'meals',
      'to_cookbook',
      'dropped_item_ids',
    ],
  );
  return CookRun(
    id: json['id'] as String,
    kind: $enumDecode(_$CookRunKindEnumMap, json['kind']),
    step: $enumDecode(_$CookRunStepEnumMap, json['step']),
    recipeId: json['recipe_id'] as String?,
    name: json['name'] as String,
    imageAssetId: json['image_asset_id'] as String?,
    imageUrl: json['image_url'] as String?,
    basePortions: (json['base_portions'] as num).toInt(),
    portions: (json['portions'] as num).toInt(),
    steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
    startedBy: json['started_by'] as String,
    startedByName: json['started_by_name'] as String,
    startedAt: const DateTimeJsonConverter().fromJson(
      json['started_at'] as DateTime,
    ),
    lines: (json['lines'] as List<dynamic>)
        .map((e) => CookRunLine.fromJson(e as Map<String, dynamic>))
        .toList(),
    pots: json['pots'] == null
        ? null
        : CookPotChoice.fromJson(json['pots'] as Map<String, dynamic>),
    withGuide: json['with_guide'] as bool,
    guideStep: (json['guide_step'] as num).toInt(),
    timers: (json['timers'] as List<dynamic>)
        .map((e) => CookTimer.fromJson(e as Map<String, dynamic>))
        .toList(),
    meals: (json['meals'] as List<dynamic>)
        .map((e) => CookMealDraft.fromJson(e as Map<String, dynamic>))
        .toList(),
    toCookbook: json['to_cookbook'] as bool,
    droppedItemIds: (json['dropped_item_ids'] as List<dynamic>)
        .map((e) => e as String)
        .toList(),
  );
}

Map<String, dynamic> _$CookRunToJson(CookRun instance) => <String, dynamic>{
  'id': instance.id,
  'kind': _$CookRunKindEnumMap[instance.kind]!,
  'step': _$CookRunStepEnumMap[instance.step]!,
  'recipe_id': instance.recipeId,
  'name': instance.name,
  'image_asset_id': instance.imageAssetId,
  'image_url': instance.imageUrl,
  'base_portions': instance.basePortions,
  'portions': instance.portions,
  'steps': instance.steps,
  'started_by': instance.startedBy,
  'started_by_name': instance.startedByName,
  'started_at': const DateTimeJsonConverter().toJson(instance.startedAt),
  'lines': instance.lines.map((e) => e.toJson()).toList(),
  'pots': instance.pots?.toJson(),
  'with_guide': instance.withGuide,
  'guide_step': instance.guideStep,
  'timers': instance.timers.map((e) => e.toJson()).toList(),
  'meals': instance.meals.map((e) => e.toJson()).toList(),
  'to_cookbook': instance.toCookbook,
  'dropped_item_ids': instance.droppedItemIds,
};

const _$CookRunKindEnumMap = {
  CookRunKind.recipe: 'recipe',
  CookRunKind.free: 'free',
};

const _$CookRunStepEnumMap = {
  CookRunStep.pots: 'pots',
  CookRunStep.assign: 'assign',
  CookRunStep.paused: 'paused',
  CookRunStep.cook: 'cook',
  CookRunStep.portion: 'portion',
};
