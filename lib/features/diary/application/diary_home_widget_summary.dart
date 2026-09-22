import 'package:yamt/features/diary/application/diary_nutrition_bars_data.dart';

/// Render-ready diary summary for today, for the home-screen widget. Hides
/// calorie-log and Burn Week internals that native widget code has no use
/// for.
class DiaryHomeWidgetSummary {
  /// Creates a diary home-widget summary.
  const new({
    required this.eatenKcal,
    required this.targetKcal,
    required this.macros,
  });

  /// Kcal eaten today, as the daily balance card counts it.
  final double eatenKcal;

  /// Today's kcal target, as the daily balance card shows it (carryover
  /// and activity included).
  final double targetKcal;

  /// Macro bars for today.
  final DiaryNutritionBarsData macros;
}
