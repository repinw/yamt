// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_update_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppVersionConfig _$AppVersionConfigFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AppVersionConfig',
      json,
      ($checkedConvert) {
        final val = AppVersionConfig(
          minVersion: $checkedConvert(
            'min_version',
            (v) => const AppVersionJsonConverter().fromJson(v as String),
          ),
          latestVersion: $checkedConvert(
            'latest_version',
            (v) => const AppVersionJsonConverter().fromJson(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'minVersion': 'min_version',
        'latestVersion': 'latest_version',
      },
    );
