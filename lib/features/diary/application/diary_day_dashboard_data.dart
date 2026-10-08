import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_mappers.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_data.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';

part 'diary_day_dashboard_data.g.dart';

// Temporary compatibility, added in 3.4.1: the JSON defaults, unknown enum
// fallbacks, and flexible converters in this file go from 3.7.0 on, once a
// migration has re-saved the stored data in the strict shape.

/// The cached part of a diary dashboard: the inputs of one day and the
/// resolved day budget.
///
/// The budget is a snapshot of the goal settings, which load later than the
/// cache on a cold start; everything else is rebuilt from the inputs by
/// [DiaryDayDashboardData.fromSnapshot].
@JsonSerializable(
  fieldRename: FieldRename.snake,
  explicitToJson: true,
  converters: [_CachedCalorieEntryConverter()],
)
class DiaryDayDashboardSnapshot {
  /// Creates a dashboard snapshot.
  const new({
    required this.selectedDay,
    required this.refreshedAt,
    required this.weekOverview,
    required this.selectedDayEntries,
    required this.plannedEntries,
    required this.runState,
    required this.goalKcal,
    required this.macroTargets,
    required this.carryoverMacroDelta,
  });

  /// Creates a snapshot from persisted cache json.
  factory fromJson(Map<String, dynamic> json) =>
      _$DiaryDayDashboardSnapshotFromJson(json);

  /// Selected diary day.
  final DateTime selectedDay;

  /// When this snapshot was loaded.
  final DateTime refreshedAt;

  /// Week overview used by balance widgets.
  final CalorieWeekOverview weekOverview;

  /// Entries for [selectedDay].
  final List<CalorieEntry> selectedDayEntries;

  /// Plans for [selectedDay].
  final List<CalorieEntry> plannedEntries;

  /// Burn Week run state used by diary chrome and balance widgets.
  final BurnWeekRunState runState;

  /// The kcal goal [selectedDay] is measured against.
  final double goalKcal;

  /// The macro targets of [selectedDay], with its carryover.
  final DiaryMacroTargets macroTargets;

  /// Change of the macro targets that the carryover of [selectedDay] causes.
  final DiaryMacroTargets carryoverMacroDelta;

  /// Converts the snapshot to persisted cache json.
  Map<String, dynamic> toJson() => _$DiaryDayDashboardSnapshotToJson(this);
}

/// Render-ready diary dashboard data for one selected day.
class DiaryDayDashboardData {
  /// Creates diary dashboard data.
  const new({
    required this.selectedDay,
    required this.refreshedAt,
    required this.weekOverview,
    required this.selectedDayEntries,
    required this.plannedEntries,
    required this.countsPlans,
    required this.runState,
    required this.mealSections,
    required this.nutritionBars,
    required this.carryoverMacroDelta,
  });

  /// Builds the dashboard of [snapshot] with [today] as today.
  factory fromSnapshot(
    DiaryDayDashboardSnapshot snapshot, {
    required DateTime today,
  }) {
    final countsPlans = DiaryDayStatus.of(
      day: snapshot.selectedDay,
      today: today,
      isPreviousDayClosed: snapshot.weekOverview.isPreviousDayClosed,
    ).isPlanned;
    return DiaryDayDashboardData(
      selectedDay: snapshot.selectedDay,
      refreshedAt: snapshot.refreshedAt,
      weekOverview: snapshot.weekOverview,
      selectedDayEntries: snapshot.selectedDayEntries,
      plannedEntries: snapshot.plannedEntries,
      countsPlans: countsPlans,
      runState: snapshot.runState,
      mealSections: buildDiaryDashboardMealSections(
        snapshot.selectedDayEntries,
        plannedEntries: snapshot.plannedEntries,
        countsPlans: countsPlans,
      ),
      nutritionBars: buildDiaryDashboardNutritionBars(
        [
          ...snapshot.selectedDayEntries,
          if (countsPlans) ...snapshot.plannedEntries,
        ],
        snapshot.goalKcal,
        macroTargets: snapshot.macroTargets,
      ),
      carryoverMacroDelta: snapshot.carryoverMacroDelta,
    );
  }

  /// Selected diary day.
  final DateTime selectedDay;

  /// When this snapshot was loaded.
  final DateTime refreshedAt;

  /// Week overview used by balance widgets.
  final CalorieWeekOverview weekOverview;

  /// Entries for [selectedDay].
  final List<CalorieEntry> selectedDayEntries;

  /// Plans for [selectedDay].
  final List<CalorieEntry> plannedEntries;

  /// Whether [plannedEntries] count toward [selectedDay]: the head, the
  /// macro bars, and the meal totals add them.
  final bool countsPlans;

  /// Burn Week run state used by diary chrome and balance widgets.
  final BurnWeekRunState runState;

  /// Meal cards for [selectedDay].
  final List<DiaryMealSection> mealSections;

  /// Macro bars for [selectedDay].
  final DiaryNutritionBarsData nutritionBars;

  /// Change of the macro targets that the carryover of [selectedDay] causes.
  final DiaryMacroTargets carryoverMacroDelta;
}

// CalorieEntry retains DateTime values for database writes. Only its cache
// representation needs ISO strings; all other fields use its generated codec.
class _CachedCalorieEntryConverter
    implements JsonConverter<CalorieEntry, Map<String, dynamic>> {
  const new();

  @override
  CalorieEntry fromJson(Map<String, dynamic> json) =>
      CalorieEntry.fromJson(json);

  @override
  Map<String, dynamic> toJson(CalorieEntry entry) => {
    ...entry.toJson(),
    'logged_at': entry.loggedAt.toIso8601String(),
    'created_at': entry.createdAt.toIso8601String(),
    'updated_at': entry.updatedAt.toIso8601String(),
  };
}
