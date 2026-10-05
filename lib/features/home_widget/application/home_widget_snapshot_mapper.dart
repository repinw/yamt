import 'package:yamt/core/theme/app_accent.dart';
import 'package:yamt/features/diary/application/diary_home_widget_summary.dart';
import 'package:yamt/features/home_widget/application/home_widget_snapshot.dart';

/// Builds the widget snapshot from today's diary summary, or `null` when
/// [summary] is `null` (no diary data loaded yet — the caller keeps the
/// widget's last synced snapshot in that case instead of writing zeros).
HomeWidgetSnapshot? buildHomeWidgetSnapshot({
  required DiaryHomeWidgetSummary? summary,
  required bool verbose,
  required AppAccent accent,
  required DateTime now,
}) {
  if (summary == null) {
    return null;
  }
  final macros = summary.macros;
  return HomeWidgetSnapshot(
    verbose: verbose,
    eatenKcal: summary.eatenKcal,
    targetKcal: summary.targetKcal,
    proteinGrams: macros.protein,
    carbsGrams: macros.carbs,
    fatGrams: macros.fat,
    proteinGoalGrams: macros.goals.protein,
    carbsGoalGrams: macros.goals.carbs,
    fatGoalGrams: macros.goals.fat,
    // The text tone of the accent reads on the widget's light and dark
    // surfaces, where the fill would not.
    accentLight: accent.light.text.toARGB32(),
    accentDark: accent.dark.text.toARGB32(),
    updatedAt: now,
  );
}
