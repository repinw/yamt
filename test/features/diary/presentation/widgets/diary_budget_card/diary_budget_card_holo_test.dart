import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/widgets/holo_foil_card.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_holo_preview_controller.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/fake_accelerometer.dart';
import '../../../../../helpers/memory_app_preferences.dart';

DiaryBudgetCardData _data({required double eatenKcal}) => DiaryBudgetCardData(
  day: DateTime(2026, 4, 27),
  status: DiaryDayStatus.today,
  metrics: DiaryDailyBalanceMetrics(
    bufferAdjustmentKcal: 0,
    realEatenKcal: eatenKcal,
    eatenKcal: eatenKcal,
    realDayLeftKcal: 2000 - eatenKcal,
    dayLeftKcal: 2000 - eatenKcal,
    targetKcal: 2000,
  ),
  isPauseDay: false,
  macros: const [],
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  DiaryBudgetCardData data,
) async {
  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
      calorieGoalControllerProvider.overrideWith(_GoalController.new),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DiaryBudgetCard(
              data: data,
              showDetails: false,
              showEaten: false,
              today: DateTime(2026, 4, 27),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  return container;
}

class _GoalController extends CalorieGoalController {
  @override
  CalorieGoalSettings build() =>
      const CalorieGoalSettings.empty().copyWith(dailyKcalGoal: 2000);
}

bool _foil(WidgetTester tester) =>
    tester.widget<HoloFoilCard>(find.byType(HoloFoilCard)).enabled;

void main() {
  testWidgets('a day away from the target has no foil', (tester) async {
    FakeAccelerometer();
    await _pump(tester, _data(eatenKcal: 1000));

    expect(_foil(tester), isFalse);
  });

  testWidgets('a day within 5 % of the target wears the foil', (tester) async {
    final sensor = FakeAccelerometer();
    await _pump(tester, _data(eatenKcal: 1950));

    expect(_foil(tester), isTrue);
    expect(sensor.isListening, isTrue);
  });

  testWidgets('the debug preview puts the foil on any day, and off again', (
    tester,
  ) async {
    FakeAccelerometer();
    final container = await _pump(tester, _data(eatenKcal: 1000));
    void toggle() =>
        container.read(diaryHoloPreviewControllerProvider.notifier).toggle();

    toggle();
    await tester.pump();
    expect(_foil(tester), isTrue);

    toggle();
    await tester.pump();
    expect(_foil(tester), isFalse);
  });
}
