import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:yamt/core/domain/date_time_json_converter.dart';

part 'cook_run_parts.g.dart';

/// The pot id of the meal of a run without pots ("Stücke zählen").
const countedMealPotId = 'counted';

/// A kitchen utensil the run cooks in, with its empty weight copied when
/// the cook chose it.
@immutable
@JsonSerializable(
  fieldRename: FieldRename.snake,
  disallowUnrecognizedKeys: true,
)
class CookPot {
  /// Creates the pot.
  const new({
    required this.id,
    required this.name,
    required this.emptyWeight,
    required this.imageStoragePath,
  });

  /// Reads a pot.
  factory fromJson(Map<String, dynamic> json) => _$CookPotFromJson(json);

  /// The utensil's id.
  @JsonKey(required: true)
  final String id;

  /// The utensil's name, if it has one.
  @JsonKey(required: true)
  final String? name;

  /// The empty weight in grams, above 0 ([CookPotsChosen] checks it).
  @JsonKey(required: true)
  final int emptyWeight;

  /// The utensil's photo in Storage, if it has one.
  @JsonKey(required: true)
  final String? imageStoragePath;

  /// The stored form.
  Map<String, dynamic> toJson() => _$CookPotToJson(this);

  @override
  bool operator ==(Object other) =>
      other is CookPot &&
      other.id == id &&
      other.name == name &&
      other.emptyWeight == emptyWeight &&
      other.imageStoragePath == imageStoragePath;

  @override
  int get hashCode => Object.hash(id, name, emptyWeight, imageStoragePath);
}

/// What the cook chose to cook in.
@immutable
sealed class CookPotChoice {
  /// Creates the choice.
  const new();

  /// Reads a choice. Throws a [FormatException] for an unknown `type`, no
  /// pots or a field too many or too few.
  factory fromJson(Map<String, dynamic> json) => switch (json) {
    {
      'type': 'pots',
      'pots': final List<dynamic> pots,
      'in_cans': final bool inCans,
    }
        when json.length == 3 && pots.isNotEmpty =>
      CookPotsChosen(
        pots: [
          for (final pot in pots) CookPot.fromJson(pot as Map<String, dynamic>),
        ],
        inCans: inCans,
      ),
    {'type': 'counted'} when json.length == 1 => const CookCounted(),
    _ => throw FormatException('Unknown pot choice: $json'),
  };

  /// The stored form, tagged with `type`.
  Map<String, dynamic> toJson();
}

/// One pot or more; each becomes its own meal.
final class CookPotsChosen extends CookPotChoice {
  /// Creates the choice. Throws an [ArgumentError] for no pots or a pot
  /// without an empty weight above 0.
  new({required List<CookPot> pots, required this.inCans})
    : pots = List.unmodifiable(pots) {
    if (pots.isEmpty) {
      throw ArgumentError.value(pots, 'pots', 'must not be empty');
    }
    if (pots.any((pot) => pot.emptyWeight <= 0)) {
      throw ArgumentError.value(pots, 'pots', 'must weigh above 0 g empty');
    }
  }

  /// The pots in the cook's order; the first takes every line without one.
  final List<CookPot> pots;

  /// Whether the food goes into cans afterwards ("Danach in Dosen"); the
  /// cans count as portions.
  final bool inCans;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'pots',
    'pots': [for (final pot in pots) pot.toJson()],
    'in_cans': inCans,
  };

  @override
  bool operator ==(Object other) =>
      other is CookPotsChosen &&
      other.inCans == inCans &&
      const ListEquality<CookPot>().equals(other.pots, pots);

  @override
  int get hashCode =>
      Object.hash(inCans, const ListEquality<CookPot>().hash(pots));
}

/// No pot: the cook counts pieces ("Ohne Topf · Stücke zählen").
final class CookCounted extends CookPotChoice {
  /// Creates the choice.
  const new();

  @override
  Map<String, dynamic> toJson() => {'type': 'counted'};

  @override
  bool operator ==(Object other) => other is CookCounted;

  @override
  int get hashCode => (CookCounted).hashCode;
}

/// A timer of a run. Only the device [deviceId] that started it rings.
@immutable
@JsonSerializable(
  fieldRename: FieldRename.snake,
  disallowUnrecognizedKeys: true,
)
class CookTimer {
  /// Creates a timer.
  const new({
    required this.id,
    required this.label,
    required this.endsAt,
    required this.deviceId,
  });

  /// Reads a timer.
  factory fromJson(Map<String, dynamic> json) => _$CookTimerFromJson(json);

  /// The timer's id.
  @JsonKey(required: true)
  final String id;

  /// What the timer is for.
  @JsonKey(required: true)
  final String label;

  /// When it rings.
  @JsonKey(required: true)
  @DateTimeJsonConverter()
  final DateTime endsAt;

  /// The device that started it.
  @JsonKey(required: true)
  final String deviceId;

  /// The stored form.
  Map<String, dynamic> toJson() => _$CookTimerToJson(this);

  /// The timer ringing at [endsAt].
  CookTimer copyWith({required DateTime endsAt}) =>
      CookTimer(id: id, label: label, endsAt: endsAt, deviceId: deviceId);

  @override
  bool operator ==(Object other) =>
      other is CookTimer &&
      other.id == id &&
      other.label == label &&
      other.endsAt == endsAt &&
      other.deviceId == deviceId;

  @override
  int get hashCode => Object.hash(id, label, endsAt, deviceId);
}

/// What the cook typed in for the meal of one pot while portioning.
@immutable
@JsonSerializable(
  fieldRename: FieldRename.snake,
  disallowUnrecognizedKeys: true,
)
class CookMealDraft {
  /// Creates the draft.
  const new({
    required this.potId,
    required this.name,
    required this.count,
    required this.inPieces,
    required this.grossWeight,
  });

  /// Reads a draft.
  factory fromJson(Map<String, dynamic> json) => _$CookMealDraftFromJson(json);

  /// The [CookPot.id], or [countedMealPotId].
  @JsonKey(required: true)
  final String potId;

  /// The meal's name.
  @JsonKey(required: true)
  final String name;

  /// Portions, cans or pieces, at least 1 (`withMeal` checks it).
  @JsonKey(required: true)
  final int count;

  /// Whether the meal is eaten in pieces.
  @JsonKey(required: true)
  final bool inPieces;

  /// The pot with the food on the scale in grams; `null` until weighed and
  /// without a pot.
  @JsonKey(required: true)
  final int? grossWeight;

  /// The stored form.
  Map<String, dynamic> toJson() => _$CookMealDraftToJson(this);

  @override
  bool operator ==(Object other) =>
      other is CookMealDraft &&
      other.potId == potId &&
      other.name == name &&
      other.count == count &&
      other.inPieces == inPieces &&
      other.grossWeight == grossWeight;

  @override
  int get hashCode => Object.hash(potId, name, count, inPieces, grossWeight);
}
