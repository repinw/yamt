// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_dashboard_layout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiaryTilePlacement _$DiaryTilePlacementFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DiaryTilePlacement', json, ($checkedConvert) {
      final val = DiaryTilePlacement(
        id: $checkedConvert('id', (v) => v as String),
        size: $checkedConvert(
          'size',
          (v) => $enumDecode(_$DiaryTileSizeEnumMap, v),
        ),
        mode: $checkedConvert('mode', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DiaryTilePlacementToJson(DiaryTilePlacement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'size': _$DiaryTileSizeEnumMap[instance.size]!,
      'mode': instance.mode,
    };

const _$DiaryTileSizeEnumMap = {
  DiaryTileSize.s1x1: 's1x1',
  DiaryTileSize.s2x1: 's2x1',
  DiaryTileSize.s2x2: 's2x2',
  DiaryTileSize.s4x1: 's4x1',
  DiaryTileSize.s4x2: 's4x2',
  DiaryTileSize.wide: 'wide',
};

DiaryDashboardLayout _$DiaryDashboardLayoutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DiaryDashboardLayout', json, ($checkedConvert) {
  final val = DiaryDashboardLayout(
    tiles: $checkedConvert(
      'tiles',
      (v) => (v as List<dynamic>)
          .map((e) => DiaryTilePlacement.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    hidden: $checkedConvert(
      'hidden',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$DiaryDashboardLayoutToJson(
  DiaryDashboardLayout instance,
) => <String, dynamic>{
  'tiles': instance.tiles.map((e) => e.toJson()).toList(),
  'hidden': instance.hidden,
};
