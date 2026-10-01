import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_progress_provider.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_demo_data.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart'
    show diaryWeeklyCheckInPlanProvider;
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_sheet/diary_weekly_checkin_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_result.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/helpers/memory_app_preferences.dart';

// 2026-09-01 is a Tuesday; the goal counts from it, so run 3 starts on 15th.
final _today = DateTime(2026, 9, 15, 9);

const _launcherKey = ValueKey<String>('weekly-checkin-launcher');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the weekly check-in plans the next run and starts the week', (
    tester,
  ) async {
    final settings = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: const CalorieCalculatorProfile.defaults().copyWith(
          trainingWeekdays: [DateTime.monday, DateTime.thursday],
          trainingDayKcalOffset: 300,
        ),
        effectiveDate: DateTime(2026, 9),
      ),
    );
    addTearDown(settings.dispose);
    final checkInData = calorieWeeklyCheckInDemoData(today: _today);
    DiaryWeeklyCheckInSheetResult? result;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
          clockProvider.overrideWithValue(() => _today),
          calorieSettingsRepositoryProvider.overrideWithValue(settings),
          calorieWeeklyCheckInDataProvider.overrideWith(
            (ref) async => checkInData,
          ),
          calorieGoalProgressProvider.overrideWith(
            (ref, endDate) async => null,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                // Keeps the plan loaded, as the diary section does.
                ref.watch(diaryWeeklyCheckInPlanProvider);
                return Center(
                  child: FilledButton(
                    key: _launcherKey,
                    onPressed: () async {
                      result = await showDiaryWeeklyCheckInSheet(
                        context,
                        checkInData: checkInData,
                      );
                    },
                    child: const Text('Open'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_launcherKey));
    await tester.pumpAndSettle();
    expect(
      find.byKey(DiaryWeeklyCheckInSheetKeys.useMeasuredChoice),
      findsOneWidget,
    );

    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton));
    await tester.pumpAndSettle();
    // The run of today suggests the Thursday and the Monday again.
    final firstDay = find.byKey(DiaryWeeklyCheckInSheetKeys.trainingDay(0));
    await tester.ensureVisible(firstDay);
    await tester.pumpAndSettle();
    await tester.tap(firstDay);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.startWeekButton));
    await tester.pumpAndSettle();

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsNothing);
    expect(result?.action, DiaryWeeklyCheckInSheetAction.apply);
    expect(result?.training?.runDay, DateTime(2026, 9, 15));
    expect(result?.training?.trainingDays, {
      DateTime(2026, 9, 15),
      DateTime(2026, 9, 17),
      DateTime(2026, 9, 21),
    });
  });
}
