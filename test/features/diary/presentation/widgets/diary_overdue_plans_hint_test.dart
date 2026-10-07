import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/quick_calorie_entry.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_overdue_plans_hint.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/memory_app_preferences.dart';
import '../../../calories/support/fake_calories_repositories.dart';
import '../../../calories/support/fake_planned_entry_repository.dart';

void main() {
  final today = DateTime(2026, 10, 7);
  final monday = DateTime(2026, 10, 5);

  CalorieGoalSettings goalSince(DateTime day) =>
      const CalorieGoalSettings.empty().copyWith(
        goalHistory: [
          CalorieGoalHistoryEntry(
            dailyKcalGoal: 2000,
            calculatorProfile: null,
            effectiveDate: day,
            changedAt: day,
          ),
        ],
      );

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required DateTime selectedDay,
    CalorieGoalSettings settings = const CalorieGoalSettings.empty(),
  }) async {
    final container = ProviderContainer(
      overrides: [
        diaryCalendarNowProvider.overrideWithValue(() => today),
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        calorieSettingsRepositoryProvider.overrideWithValue(
          FakeCalorieSettingsRepository(initialSettings: settings),
        ),
        plannedEntryRepositoryProvider.overrideWithValue(
          FakePlannedEntryRepository(
            plans: [
              buildQuickCalorieEntry(
                id: 'pasta',
                userId: 'user-1',
                name: 'Pasta',
                mealType: MealType.dinner,
                loggedAt: monday.add(const Duration(hours: 19)),
                now: monday,
                kcal: 700,
              ),
            ],
          ),
        ),
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
          home: Scaffold(body: DiaryOverduePlansHint(selectedDay: selectedDay)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('today names the day with plans left; a tap opens it', (
    tester,
  ) async {
    final container = await pump(
      tester,
      selectedDay: today,
      settings: goalSince(DateTime(2026, 9)),
    );

    expect(find.text('Open plans from Mon, Oct 5'), findsOneWidget);
    await tester.tap(find.byKey(DiaryOverduePlansHint.lineKey));
    await tester.pump();

    expect(container.read(diaryCalendarControllerProvider).selectedDay, monday);
  });

  testWidgets('the close button hides the line', (tester) async {
    await pump(
      tester,
      selectedDay: today,
      settings: goalSince(DateTime(2026, 9)),
    );

    await tester.tap(find.byKey(DiaryOverduePlansHint.closeKey));
    await tester.pumpAndSettle();

    expect(find.byKey(DiaryOverduePlansHint.lineKey), findsNothing);
  });

  testWidgets('a day the calendar cannot open is not named', (tester) async {
    // Without a goal, the calendar starts at today.
    await pump(tester, selectedDay: today);

    expect(find.byKey(DiaryOverduePlansHint.lineKey), findsNothing);
  });

  testWidgets('another day shows no hint', (tester) async {
    await pump(
      tester,
      selectedDay: monday,
      settings: goalSince(DateTime(2026, 9)),
    );

    expect(find.byKey(DiaryOverduePlansHint.lineKey), findsNothing);
  });
}
