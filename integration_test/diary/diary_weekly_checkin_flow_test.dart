import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_controller.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_section/diary_weekly_checkin_section.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_sheet/diary_weekly_checkin_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_result.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/features/calories/support/fake_planned_entry_repository.dart';
import '../../test/helpers/memory_app_preferences.dart';

// 2026-09-01 is a Tuesday. The goal counts from it, so its first check-in
// window is Sep 1–7 and is due on Sep 8, the first day of run 2.
final _goalStart = DateTime(2026, 9);
final _now = DateTime(2026, 9, 8, 9);

const _launcherKey = ValueKey<String>('weekly-checkin-launcher');

CalorieEntry _entry(int day, double kcal) {
  final loggedAt = DateTime(2026, 9, day, 12);
  return CalorieEntry.create(
    id: 'entry-$day',
    userId: 'user-1',
    name: 'Lunch $day',
    mealType: MealType.lunch,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: kcal,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 2,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

List<Override> _overrides(
  FakeCalorieSettingsRepository settings,
  FakeCalorieLogRepository log,
) => [
  appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
  clockProvider.overrideWithValue(() => _now),
  calorieSettingsRepositoryProvider.overrideWithValue(settings),
  calorieLogRepositoryProvider.overrideWithValue(log),
  plannedEntryRepositoryProvider.overrideWithValue(
    FakePlannedEntryRepository(),
  ),
  burnWeekRunStateRepositoryProvider.overrideWithValue(
    FakeBurnWeekRunStateRepository(),
  ),
  healthConnectionServiceProvider.overrideWith(
    (ref) =>
        FakeHealthConnectionService(const HealthConnectionStatus.unsupported()),
  ),
  healthWeightServiceProvider.overrideWith(
    (ref) => FakeHealthWeightService(const []),
  ),
  manualHealthWeightRepositoryProvider.overrideWith(
    (ref) => FakeManualHealthWeightRepository([
      ManualHealthWeightEntry(day: _goalStart, weightKg: 82),
      ManualHealthWeightEntry(day: DateTime(2026, 9, 7), weightKg: 81.4),
    ]),
  ),
];

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
        effectiveDate: _goalStart,
      ),
    );
    final log = FakeCalorieLogRepository(
      initialEntries: [
        for (var day = 1; day <= 7; day++) _entry(day, 1900 + day * 10),
      ],
    );
    addTearDown(settings.dispose);
    addTearDown(log.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(settings, log),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            // Opens the sheet and saves its result, as the diary check-in
            // section does.
            body: Consumer(
              builder: (context, ref, _) {
                final checkInData = ref
                    .watch(calorieWeeklyCheckInDataProvider)
                    .value;
                ref.watch(calorieWeeklyCheckInControllerProvider);
                return Center(
                  child: FilledButton(
                    key: _launcherKey,
                    onPressed: checkInData == null
                        ? null
                        : () async {
                            final result = await showDiaryWeeklyCheckInSheet(
                              context,
                              checkInData: checkInData,
                            );
                            if (result?.action ==
                                DiaryWeeklyCheckInSheetAction.apply) {
                              await ref
                                  .read(
                                    calorieWeeklyCheckInControllerProvider
                                        .notifier,
                                  )
                                  .applyWeeklyCheckIn(
                                    checkInData,
                                    training: result!.training,
                                  );
                            }
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
    // Run 2 suggests the Thursday and the Monday of run 1; add its Tuesday.
    final firstDay = find.byKey(DiaryWeeklyCheckInSheetKeys.trainingDay(0));
    await tester.ensureVisible(firstDay);
    await tester.pumpAndSettle();
    await tester.tap(firstDay);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton));
    await tester.pumpAndSettle();
    // The photo step: pose chips and the slot for today's photo.
    expect(
      find.byKey(DiaryWeeklyCheckInSheetKeys.photoPose('front')),
      findsOneWidget,
    );
    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.photoAdd), findsOneWidget);
    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.startWeekButton));
    await tester.pumpAndSettle();

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsNothing);
    final saved = await settings.readSettings();
    expect(saved.pendingWeeklyCheckIn, isNull);
    expect(saved.isTrainingDay(DateTime(2026, 9, 8)), isTrue);
    expect(saved.isTrainingDay(DateTime(2026, 9, 9)), isFalse);
    expect(saved.isTrainingDay(DateTime(2026, 9, 10)), isTrue);
    expect(saved.isTrainingDay(DateTime(2026, 9, 14)), isTrue);
  });

  testWidgets('redo on the success card reopens the decided check-in', (
    tester,
  ) async {
    final settings = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: const CalorieCalculatorProfile.defaults(),
        effectiveDate: _goalStart,
      ),
    );
    final log = FakeCalorieLogRepository(
      initialEntries: [
        for (var day = 1; day <= 7; day++) _entry(day, 1900 + day * 10),
      ],
    );
    addTearDown(settings.dispose);
    addTearDown(log.dispose);

    await _pumpSection(tester, settings, log);

    // The section opens the due check-in; apply it as it is.
    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);
    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.startWeekButton));
    await tester.pumpAndSettle();
    expect((await settings.readSettings()).pendingWeeklyCheckIn, isNull);

    await tester.tap(find.byKey(DiaryWeeklyCheckInCardKeys.successCardRedo));
    await tester.pumpAndSettle();

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);
    expect(
      (await settings.readSettings()).pendingWeeklyCheckIn?.windowStartDate,
      _goalStart,
    );
  });

  testWidgets('back from the goal sheet returns to the check-in as it was', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final settings = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: const CalorieCalculatorProfile.defaults().copyWith(
          trainingWeekdays: [DateTime.monday, DateTime.thursday],
          trainingDayKcalOffset: 300,
        ),
        effectiveDate: _goalStart,
      ),
    );
    final log = FakeCalorieLogRepository(
      initialEntries: [
        for (var day = 1; day <= 7; day++) _entry(day, 1900 + day * 10),
      ],
    );
    addTearDown(settings.dispose);
    addTearDown(log.dispose);
    // Reads the selection as a screen reader does, so it needs no text.
    void expectSelected(Key key, {bool isSelected = true}) => expect(
      tester.getSemantics(find.byKey(key)),
      isSemantics(isSelected: isSelected),
      reason: 'Selection of $key',
    );

    await _pumpSection(tester, settings, log);

    // The section opens the due check-in. Keep the previous TDEE and add the
    // Tuesday of run 2 to its Thursday and Monday.
    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);
    await _tapByKey(tester, DiaryWeeklyCheckInSheetKeys.keepPreviousChoice);
    await _tapByKey(tester, DiaryWeeklyCheckInSheetKeys.nextButton);
    await _tapByKey(tester, DiaryWeeklyCheckInSheetKeys.trainingDay(0));
    expectSelected(DiaryWeeklyCheckInSheetKeys.trainingDay(0));
    await _tapByKey(tester, DiaryWeeklyCheckInSheetKeys.backButton);

    // "Change goal" swaps the check-in for the goal sheet; its arrow goes
    // back without a new goal.
    await _tapByKey(tester, DiaryWeeklyCheckInSheetKeys.changeGoalButton);
    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsNothing);
    await _tapByKey(tester, CalorieGoalCalculatorSheetKeys.sheetBackButton);

    // The check-in is open again on the review step, with the previous TDEE.
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.sheetBackButton),
      findsNothing,
    );
    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);
    expect(
      find.byKey(DiaryWeeklyCheckInSheetKeys.changeGoalButton),
      findsOneWidget,
    );
    expect(
      find.byKey(DiaryWeeklyCheckInSheetKeys.trainingDay(0)),
      findsNothing,
    );
    expectSelected(DiaryWeeklyCheckInSheetKeys.keepPreviousChoice);
    expectSelected(
      DiaryWeeklyCheckInSheetKeys.useMeasuredChoice,
      isSelected: false,
    );

    // The training step still plans the added Tuesday.
    await _tapByKey(tester, DiaryWeeklyCheckInSheetKeys.nextButton);
    expectSelected(DiaryWeeklyCheckInSheetKeys.trainingDay(0));
    expectSelected(
      DiaryWeeklyCheckInSheetKeys.trainingDay(1),
      isSelected: false,
    );
    expectSelected(DiaryWeeklyCheckInSheetKeys.trainingDay(2));

    // Nothing was decided: no new goal, and the check-in is still pending.
    final saved = await settings.readSettings();
    expect(saved.goalHistory, hasLength(1));
    expect(saved.pendingWeeklyCheckIn?.windowStartDate, _goalStart);
    expect(saved.pendingWeeklyCheckIn?.isDismissed, isFalse);
    expect(saved.isTrainingDay(DateTime(2026, 9, 8)), isFalse);
    semantics.dispose();
  });
}

/// Shows the diary check-in section, which opens a due check-in itself.
Future<void> _pumpSection(
  WidgetTester tester,
  FakeCalorieSettingsRepository settings,
  FakeCalorieLogRepository log,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(settings, log),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DiaryWeeklyCheckInSection(selectedDay: _now),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Scrolls the widget with [key] into view and taps it.
Future<void> _tapByKey(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
