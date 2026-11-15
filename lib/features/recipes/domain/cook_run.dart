import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:yamt/core/domain/date_time_json_converter.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

part 'cook_run.g.dart';

/// What a cook run cooks.
enum CookRunKind {
  /// A recipe of the Kochbuch.
  recipe,

  /// Free cooking without a recipe.
  free,
}

/// The step a cook run is on. A finished or discarded run is deleted, so it
/// has no step.
enum CookRunStep {
  /// Choosing the pots.
  pots,

  /// Assigning the lines to the Vorrat ("Zuweisen").
  assign,

  /// Waiting for the shopping.
  paused,

  /// Cooking.
  cook,

  /// Splitting into meals.
  portion,
}

/// One cooking ("Kochvorgang") of the household. Everyone in the household
/// can go on with it, portion it or discard it. Its takes reserve Vorrat
/// items until it ends.
@immutable
@JsonSerializable(
  fieldRename: FieldRename.snake,
  explicitToJson: true,
  disallowUnrecognizedKeys: true,
)
class CookRun {
  /// Creates a cook run. Throws an [ArgumentError] for [basePortions] or
  /// [portions] below 1.
  new({
    required this.id,
    required this.kind,
    required this.step,
    required this.recipeId,
    required this.name,
    required this.imageAssetId,
    required this.imageUrl,
    required this.basePortions,
    required this.portions,
    required this.steps,
    required this.startedBy,
    required this.startedByName,
    required this.startedAt,
    required this.lines,
    required this.pots,
    required this.withGuide,
    required this.guideStep,
    required this.timers,
    required this.meals,
    required this.toCookbook,
    required this.droppedItemIds,
  }) {
    if (basePortions < 1 || portions < 1) {
      throw ArgumentError('Cook run $id needs portions of at least 1.');
    }
  }

  /// Reads a cook run.
  factory fromJson(Map<String, dynamic> json) => _$CookRunFromJson(json);

  /// `recipe-<templateId>` for a recipe, a uuid for free cooking.
  @JsonKey(required: true)
  final String id;

  /// What the run cooks.
  @JsonKey(required: true)
  final CookRunKind kind;

  /// The step the run is on.
  @JsonKey(required: true)
  final CookRunStep step;

  /// The recipe template, `null` for free cooking.
  @JsonKey(required: true)
  final String? recipeId;

  /// The recipe's name, or the name of free cooking.
  @JsonKey(required: true)
  final String name;

  /// The recipe's image asset.
  @JsonKey(required: true)
  final String? imageAssetId;

  /// The recipe's image address.
  @JsonKey(required: true)
  final String? imageUrl;

  /// The portions the recipe is written for; 1 for free cooking.
  @JsonKey(required: true)
  final int basePortions;

  /// The portions this cooking makes.
  @JsonKey(required: true)
  final int portions;

  /// The recipe's instructions, empty for free cooking.
  @JsonKey(required: true)
  final List<String> steps;

  /// The uid of the member who started the run.
  @JsonKey(required: true)
  final String startedBy;

  /// That member's name when the run started.
  @JsonKey(required: true)
  final String startedByName;

  /// When the run started.
  @JsonKey(required: true)
  @DateTimeJsonConverter()
  final DateTime startedAt;

  /// The lines, in the recipe's order and then as added.
  @JsonKey(required: true)
  final List<CookRunLine> lines;

  /// What the run cooks in, `null` until the cook chose.
  @JsonKey(required: true)
  final CookPotChoice? pots;

  /// Whether the cook follows the guide ("Kochhelfer").
  @JsonKey(required: true)
  final bool withGuide;

  /// The instruction the guide shows.
  @JsonKey(required: true)
  final int guideStep;

  /// The running timers.
  @JsonKey(required: true)
  final List<CookTimer> timers;

  /// The meals typed in while portioning, one per pot.
  @JsonKey(required: true)
  final List<CookMealDraft> meals;

  /// Whether free cooking ends with a new Kochbuch recipe.
  @JsonKey(required: true)
  final bool toCookbook;

  /// Items that search, barcode or AI put into the Vorrat for lines the
  /// cook removed since; they count like [CookRunLine.addedItemIds].
  @JsonKey(required: true)
  final List<String> droppedItemIds;

  /// The stored form.
  Map<String, dynamic> toJson() => _$CookRunToJson(this);

  /// A copy with the given fields replaced.
  CookRun copyWith({
    CookRunStep? step,
    int? portions,
    List<CookRunLine>? lines,
    CookPotChoice? pots,
    bool? withGuide,
    int? guideStep,
    List<CookTimer>? timers,
    List<CookMealDraft>? meals,
    bool? toCookbook,
    List<String>? droppedItemIds,
  }) => CookRun(
    id: id,
    kind: kind,
    step: step ?? this.step,
    recipeId: recipeId,
    name: name,
    imageAssetId: imageAssetId,
    imageUrl: imageUrl,
    basePortions: basePortions,
    portions: portions ?? this.portions,
    steps: steps,
    startedBy: startedBy,
    startedByName: startedByName,
    startedAt: startedAt,
    lines: lines ?? this.lines,
    pots: pots ?? this.pots,
    withGuide: withGuide ?? this.withGuide,
    guideStep: guideStep ?? this.guideStep,
    timers: timers ?? this.timers,
    meals: meals ?? this.meals,
    toCookbook: toCookbook ?? this.toCookbook,
    droppedItemIds: droppedItemIds ?? this.droppedItemIds,
  );

  /// The id of this one cooking. [id] comes back with every cooking of a
  /// recipe; [startedAt] tells them apart and stays the same on a retry.
  String get cookingId => '$id-${startedAt.millisecondsSinceEpoch}';

  /// Every item that search, barcode or AI put into the Vorrat for the run.
  Set<String> get addedItemIds => {
    for (final line in lines) ...line.addedItemIds,
    ...droppedItemIds,
  };

  /// The line [lineId], or `null`.
  CookRunLine? lineOf(String lineId) =>
      lines.firstWhereOrNull((line) => line.id == lineId);

  /// How many lines are not settled yet.
  int get openCount =>
      lines.where((line) => line.settlement is LineOpen).length;

  /// How many lines wait for the shopping.
  int get shoppingCount =>
      lines.where((line) => line.settlement is LineShopping).length;

  /// Whether the cook still assigns before cooking ("Zutaten zuordnen"): a
  /// line of the recipe or one added while assigning is open or waits for
  /// the shopping. Lines that came in while cooking do not count; free
  /// cooking never assigns.
  bool get needsAssigning =>
      kind == CookRunKind.recipe &&
      lines.any(
        (line) =>
            line.origin != CookLineOrigin.cooking &&
            (line.settlement is LineOpen || line.settlement is LineShopping),
      );

  /// What the run takes from each item, by item id.
  Map<String, int> get reservations {
    final sums = <String, int>{};
    for (final line in lines) {
      if (line.settlement case LineAssigned(:final takes)) {
        for (final take in takes) {
          sums[take.itemId] = (sums[take.itemId] ?? 0) + take.amount;
        }
      }
    }
    return sums;
  }

  List<Object?> get _props => [
    id,
    kind,
    step,
    recipeId,
    name,
    imageAssetId,
    imageUrl,
    basePortions,
    portions,
    steps,
    startedBy,
    startedByName,
    startedAt,
    lines,
    pots,
    withGuide,
    guideStep,
    timers,
    meals,
    toCookbook,
    droppedItemIds,
  ];

  @override
  bool operator ==(Object other) =>
      other is CookRun &&
      const DeepCollectionEquality().equals(other._props, _props);

  @override
  int get hashCode => const DeepCollectionEquality().hash(_props);
}

/// What all [runs] together take from each item, by item id.
Map<String, int> reservationsOf(Iterable<CookRun> runs) {
  final sums = <String, int>{};
  for (final run in runs) {
    for (final MapEntry(:key, :value) in run.reservations.entries) {
      sums[key] = (sums[key] ?? 0) + value;
    }
  }
  return sums;
}
