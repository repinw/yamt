// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whats_new_release.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WhatsNewRelease _$WhatsNewReleaseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const ['de', 'en'],
    requiredKeys: const ['de', 'en'],
  );
  return WhatsNewRelease(
    de: WhatsNewNotes.fromJson(json['de'] as Map<String, dynamic>),
    en: WhatsNewNotes.fromJson(json['en'] as Map<String, dynamic>),
  );
}

WhatsNewNotes _$WhatsNewNotesFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const ['new', 'improved', 'fixed'],
    requiredKeys: const ['new', 'improved', 'fixed'],
  );
  return WhatsNewNotes(
    added: (json['new'] as List<dynamic>).map((e) => e as String).toList(),
    improved: (json['improved'] as List<dynamic>)
        .map((e) => e as String)
        .toList(),
    fixed: (json['fixed'] as List<dynamic>).map((e) => e as String).toList(),
  );
}
