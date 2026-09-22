import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_data.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_home_widget_summary_provider.dart';

import '../support/diary_dashboard_test_support.dart';

void main() {
  final now = DateTime(2026, 9, 22, 12);
  final normalizedDay = normalizeDiaryDay(now);

  ProviderContainer containerWith(DiaryDayDashboardState state) {
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        diaryDayDashboardControllerProvider(normalizedDay)
            .overrideWith(() => FakeDiaryDayDashboardController(state)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test("is null while today's dashboard has not loaded yet", () {
    final container = containerWith(
      diaryDashboardErrorStateForTest(Exception('boom')),
    );

    expect(container.read(diaryHomeWidgetSummaryProvider), isNull);
  });

  test('uses the daily balance card metrics and the macro bars', () {
    const macros = DiaryNutritionBarsData(
      carbs: 100,
      protein: 80,
      fat: 40,
      goals: DiaryMacroTargets(carbs: 200, protein: 150, fat: 70),
    );
    final container = containerWith(
      diaryDashboardLoadedStateForTest(
        selectedDay: normalizedDay,
        weekOverview: diaryWeekOverviewForTest(
          selectedDay: normalizedDay,
          dayTotals: [0, 0, 0, 0, 0, 0, 1200],
        ),
        nutritionBars: macros,
      ),
    );

    final summary = container.read(diaryHomeWidgetSummaryProvider)!;

    expect(summary.eatenKcal, 1200);
    expect(summary.targetKcal, 2000);
    expect(summary.macros, same(macros));
  });
}
