// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_run_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CookLineConversion _$CookLineConversionFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const ['amount_per_piece', 'unit'],
    requiredKeys: const ['amount_per_piece', 'unit'],
  );
  return CookLineConversion(
    amountPerPiece: (json['amount_per_piece'] as num).toInt(),
    unit: _readUnit(json['unit'] as String),
  );
}

Map<String, dynamic> _$CookLineConversionToJson(CookLineConversion instance) =>
    <String, dynamic>{
      'amount_per_piece': instance.amountPerPiece,
      'unit': _writeUnit(instance.unit),
    };

CookRoughWeight _$CookRoughWeightFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const ['amount', 'unit'],
    requiredKeys: const ['amount', 'unit'],
  );
  return CookRoughWeight(
    amount: (json['amount'] as num).toInt(),
    unit: _readWeightUnit(json['unit'] as String),
  );
}

Map<String, dynamic> _$CookRoughWeightToJson(CookRoughWeight instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'unit': _writeUnit(instance.unit),
    };

CookRunLine _$CookRunLineFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const [
      'id',
      'text',
      'origin',
      'conversion',
      'amount',
      'amount_portions',
      'amount_unit',
      'settlement',
      'weighed',
      'pot_id',
      'added_item_ids',
      'rough_weight',
    ],
    requiredKeys: const [
      'id',
      'text',
      'origin',
      'conversion',
      'amount',
      'amount_portions',
      'settlement',
      'weighed',
      'pot_id',
      'added_item_ids',
    ],
  );
  return CookRunLine(
    id: json['id'] as String,
    text: json['text'] as String,
    origin: $enumDecode(_$CookLineOriginEnumMap, json['origin']),
    conversion: json['conversion'] == null
        ? null
        : CookLineConversion.fromJson(
            json['conversion'] as Map<String, dynamic>,
          ),
    amount: (json['amount'] as num?)?.toInt(),
    amountPortions: (json['amount_portions'] as num?)?.toInt(),
    amountUnit: _readOptionalUnit(json['amount_unit'] as String?),
    settlement: LineSettlement.fromJson(
      json['settlement'] as Map<String, dynamic>,
    ),
    weighed: (json['weighed'] as num?)?.toInt(),
    potId: json['pot_id'] as String?,
    addedItemIds: (json['added_item_ids'] as List<dynamic>)
        .map((e) => e as String)
        .toList(),
    roughWeight: json['rough_weight'] == null
        ? null
        : CookRoughWeight.fromJson(
            json['rough_weight'] as Map<String, dynamic>,
          ),
  );
}

Map<String, dynamic> _$CookRunLineToJson(CookRunLine instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'origin': _$CookLineOriginEnumMap[instance.origin]!,
      'conversion': instance.conversion?.toJson(),
      'amount': instance.amount,
      'amount_portions': instance.amountPortions,
      'amount_unit': ?_writeOptionalUnit(instance.amountUnit),
      'settlement': instance.settlement.toJson(),
      'weighed': instance.weighed,
      'pot_id': instance.potId,
      'added_item_ids': instance.addedItemIds,
      'rough_weight': ?instance.roughWeight?.toJson(),
    };

const _$CookLineOriginEnumMap = {
  CookLineOrigin.recipe: 'recipe',
  CookLineOrigin.added: 'added',
  CookLineOrigin.cooking: 'cooking',
};
