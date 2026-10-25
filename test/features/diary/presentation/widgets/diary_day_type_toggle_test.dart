import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_toggle.dart';
import 'package:yamt/features/home/presentation/widgets/home_action_panel.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/home_shell_test_scope.dart';
import '../../../calories/support/fake_calories_repositories.dart';

// 2026-04-27 is a Monday, the training weekday; the 29th is a pause day.
final _monday = DateTime(2026, 4, 27);
final _tuesday = DateTime(2026, 4, 28);
final _wednesday = DateTime(2026, 4, 29);

final CalorieGoalSettings _settings = const CalorieGoalSettings.empty()
    .copyWith(
      dailyKcalGoal: 2200,
      trainingWeekdays: const [DateTime.monday],
      trainingDayKcalOffset: 300,
      pauseDayKeys: [localDayKey(_wednesday)],
    );

void main() {
  /// Shows the toggle on [day] with the calorie goal of [settings], inside
  /// the home shell unless [inShell] is false.
  Future<FakeCalorieSettingsRepository> pumpToggle(
    WidgetTester tester,
    DateTime day, {
    CalorieGoalSettings? settings,
    bool inShell = true,
  }) async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: settings ?? _settings,
    );
    addTearDown(repository.dispose);
    const toggle = Center(child: DiaryDayTypeToggle());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(
            () => day.add(const Duration(hours: 12)),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: inShell ? const HomeShellTestScope(child: toggle) : toggle,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  final cases = <DateTime, (String, String)>{
    _monday: ('🏋️', 'TRAINING'),
    _tuesday: ('🛋️', 'RUHETAG'),
    _wednesday: ('⏸️', 'PAUSE'),
  };

  for (final MapEntry(key: day, value: (emoji, word)) in cases.entries) {
    testWidgets('shows the emoji over the short name for $day', (tester) async {
      await pumpToggle(tester, day);

      expect(find.text(emoji), findsOneWidget);
      expect(find.text(word), findsOneWidget);
    });
  }

  testWidgets('shows nothing without a calorie goal', (tester) async {
    await pumpToggle(
      tester,
      _monday,
      settings: const CalorieGoalSettings.empty(),
    );

    expect(find.byKey(DiaryDayTypeToggle.buttonKey), findsNothing);
  });

  testWidgets('shows nothing outside the home shell', (tester) async {
    await pumpToggle(tester, _monday, inShell: false);

    expect(find.byKey(DiaryDayTypeToggle.buttonKey), findsNothing);
  });

  testWidgets('a tap opens the day types from the top with the current one '
      'highlighted', (tester) async {
    await pumpToggle(tester, _monday);

    await tester.tap(find.byKey(DiaryDayTypeToggle.buttonKey));
    await tester.pumpAndSettle();

    final panel = tester.widget<HomeActionPanel>(find.byType(HomeActionPanel));
    expect(panel.fromTop, isTrue);
    expect(
      panel.highlightedKey,
      DiaryDayTypeToggle.optionKey(DiaryDayType.training),
    );
    for (final type in DiaryDayType.values) {
      expect(find.byKey(DiaryDayTypeToggle.optionKey(type)), findsOneWidget);
    }
    expect(find.text('TAGES-STATUS'), findsOneWidget);
    expect(find.text('+300 kcal gegenüber einem Ruhetag'), findsOneWidget);
    expect(
      find.text('Neutraler Tag (Urlaub, Krankheit). Kein Streak-Bruch.'),
      findsOneWidget,
    );
  });

  testWidgets('picking rest closes the panel and saves the rest day', (
    tester,
  ) async {
    final repository = await pumpToggle(tester, _monday);

    await tester.tap(find.byKey(DiaryDayTypeToggle.buttonKey));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(DiaryDayTypeToggle.optionKey(DiaryDayType.rest)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeActionPanel), findsNothing);
    expect(find.text('RUHETAG'), findsOneWidget);
    final saved = await repository.readSettings();
    expect(saved.isTrainingDay(_monday), isFalse);
    expect(saved.isPauseDay(_monday), isFalse);
  });

  testWidgets('picking pause marks the day as a pause day', (tester) async {
    final repository = await pumpToggle(tester, _tuesday);

    await tester.tap(find.byKey(DiaryDayTypeToggle.buttonKey));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(DiaryDayTypeToggle.optionKey(DiaryDayType.pause)),
    );
    await tester.pumpAndSettle();

    expect(find.text('PAUSE'), findsOneWidget);
    expect((await repository.readSettings()).isPauseDay(_tuesday), isTrue);
  });
}
