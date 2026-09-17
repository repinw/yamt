import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_toggle.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _FakeCalorieGoalController extends CalorieGoalController {
  new(this.settings);

  final CalorieGoalSettings settings;

  @override
  CalorieGoalSettings build() => settings;
}

class _FixedDiaryCalendarController extends DiaryCalendarController {
  new(this.day);

  final DateTime day;

  @override
  DiaryCalendarState build() {
    return DiaryCalendarState(today: day, selectedDay: day);
  }
}

void main() {
  final settings = const CalorieGoalSettings.empty().copyWith(
    dailyKcalGoal: 2200,
    trainingWeekdays: const [DateTime.monday],
    pauseDayKeys: [diaryDayKey(DateTime(2026, 4, 29))],
  );

  Future<void> pumpToggle(WidgetTester tester, DateTime day) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          calorieGoalControllerProvider.overrideWith(
            () => _FakeCalorieGoalController(settings),
          ),
          diaryCalendarControllerProvider.overrideWith(
            () => _FixedDiaryCalendarController(day),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Center(child: DiaryDayTypeToggle())),
        ),
      ),
    );
  }

  final cases = <DateTime, String>{
    DateTime(2026, 4, 27): '🏋️',
    DateTime(2026, 4, 28): '🛋️',
    DateTime(2026, 4, 29): '⏸️',
  };

  for (final entry in cases.entries) {
    testWidgets('shows only ${entry.value} for ${entry.key}', (tester) async {
      await pumpToggle(tester, entry.key);
      await tester.pump();

      expect(find.text(entry.value), findsOneWidget);
      expect(find.text('Trainingstag'), findsNothing);
      expect(find.text('Ruhetag'), findsNothing);
      expect(find.text('Pausentag'), findsNothing);
    });
  }

  testWidgets('tapping the emoji opens the day type sheet', (tester) async {
    await pumpToggle(tester, DateTime(2026, 4, 27));
    await tester.pump();

    await tester.tap(find.byKey(DiaryDayTypeToggle.buttonKey));
    await tester.pumpAndSettle();

    expect(find.text('Tages-Status wählen'), findsOneWidget);
    expect(find.text('🏋️ Trainingstag'), findsOneWidget);
  });
}
