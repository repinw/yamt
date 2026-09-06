import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_data.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';

part 'diary_day_dashboard_data.g.dart';

/// Render-ready diary dashboard data for one selected day.
@JsonSerializable(
  fieldRename: FieldRename.snake,
  explicitToJson: true,
  converters: [_CachedCalorieEntryConverter()],
)
class DiaryDayDashboardData {
  /// Creates diary dashboard data.
  const DiaryDayDashboardData({
    required this.selectedDay,
    required this.refreshedAt,
    required this.weekOverview,
    required this.selectedDayEntries,
    required this.runState,
    required this.mealSections,
    required this.nutritionBars,
  });

  /// Creates data from persisted cache json.
  factory DiaryDayDashboardData.fromJson(Map<String, dynamic> json) =>
      _$DiaryDayDashboardDataFromJson(json);

  /// Selected diary day.
  final DateTime selectedDay;

  /// When this snapshot was loaded.
  final DateTime refreshedAt;

  /// Week overview used by balance widgets.
  final CalorieWeekOverview weekOverview;

  /// Entries for [selectedDay].
  final List<CalorieEntry> selectedDayEntries;

  /// Burn Week run state used by diary chrome and balance widgets.
  final BurnWeekRunState runState;

  /// Meal cards for [selectedDay].
  final List<DiaryMealSection> mealSections;

  /// Macro bars for [selectedDay].
  final DiaryNutritionBarsData nutritionBars;

  /// Converts data to persisted cache json.
  Map<String, dynamic> toJson() => _$DiaryDayDashboardDataToJson(this);
}

// CalorieEntry retains DateTime values for database writes. Only its cache
// representation needs ISO strings; all other fields use its generated codec.
class _CachedCalorieEntryConverter
    implements JsonConverter<CalorieEntry, Map<String, dynamic>> {
  const _CachedCalorieEntryConverter();

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
