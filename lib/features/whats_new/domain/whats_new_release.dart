import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:yamt/core/domain/app_version.dart';

part 'whats_new_release.g.dart';

/// The release notes of one app version in German and English, read from
/// `assets/whats_new/<version>.json`.
@immutable
@JsonSerializable(createToJson: false, disallowUnrecognizedKeys: true)
class WhatsNewRelease {
  /// Creates the notes in both languages.
  const new({required this.de, required this.en});

  /// Reads the notes strictly: both languages, each with all three lists.
  factory fromJson(Map<String, dynamic> json) =>
      _$WhatsNewReleaseFromJson(json);

  /// German notes.
  @JsonKey(required: true)
  final WhatsNewNotes de;

  /// English notes.
  @JsonKey(required: true)
  final WhatsNewNotes en;

  /// The notes in [languageCode], English for any language but German.
  WhatsNewNotes notesFor(String languageCode) => languageCode == 'de' ? de : en;
}

/// The release notes of one version in one language.
@immutable
@JsonSerializable(createToJson: false, disallowUnrecognizedKeys: true)
class WhatsNewNotes {
  /// Creates the notes.
  const new({required this.added, required this.improved, required this.fixed});

  /// Reads the notes strictly.
  factory fromJson(Map<String, dynamic> json) => _$WhatsNewNotesFromJson(json);

  /// What is new.
  @JsonKey(name: 'new', required: true)
  final List<String> added;

  /// What got better.
  @JsonKey(required: true)
  final List<String> improved;

  /// What was fixed.
  @JsonKey(required: true)
  final List<String> fixed;

  /// The point the notice names: the first new one, else the first of the
  /// others; null when the notes are empty.
  String? get headline => [...added, ...improved, ...fixed].firstOrNull;
}

/// What the app does on start with the notes of the running version.
enum WhatsNewStep {
  /// Show the notice.
  show,

  /// Store the version without a notice: a fresh install has nothing new.
  markSeen,

  /// Do nothing: the notes of this version were shown before.
  skip,
}

/// Decides the [WhatsNewStep] for the [running] version, the last version
/// whose notes this device saw ([lastSeen]), and whether the app was
/// [usedBefore] on this device.
WhatsNewStep whatsNewStep({
  required AppVersion running,
  required AppVersion? lastSeen,
  required bool usedBefore,
}) {
  if (lastSeen != null && !lastSeen.isBefore(running)) {
    return WhatsNewStep.skip;
  }
  if (lastSeen == null && !usedBefore) {
    return WhatsNewStep.markSeen;
  }
  return WhatsNewStep.show;
}
