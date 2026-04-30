import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_intro_dialog.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  test('DiaryIntroData rejects incomplete goal settings', () {
    const settings = CalorieGoalSettings.empty();

    expect(DiaryIntroData.canBuildFrom(settings), isFalse);
    expect(
      () => DiaryIntroData.fromSettings(settings),
      throwsA(isA<ArgumentError>()),
    );
  });

  testWidgets('intro dialog navigates back to the start page', (tester) async {
    await _pumpIntroDialog(tester);

    expect(find.text('Your starting point'), findsOneWidget);

    await tester.tap(find.byKey(DiaryIntroDialogKeys.nextButton));
    await tester.pumpAndSettle();
    expect(find.text('Your goal'), findsOneWidget);

    await tester.tap(find.byKey(DiaryIntroDialogKeys.backButton));
    await tester.pumpAndSettle();
    expect(find.text('Your starting point'), findsOneWidget);
  });

  testWidgets('intro activity page hides Health button without action', (
    tester,
  ) async {
    await _pumpIntroDialog(tester);
    await _goToActivityPage(tester);

    expect(find.text('Activity'), findsOneWidget);
    expect(find.byKey(DiaryIntroDialogKeys.healthActionButton), findsNothing);
  });

  testWidgets('intro activity page labels Health actions', (tester) async {
    var pressedCount = 0;

    await _pumpIntroDialog(
      tester,
      healthAction: DiaryIntroHealthAction(
        accessState: HealthDataAccessState.installRequired,
        hasConnectionError: false,
        onPressed: () {
          pressedCount += 1;
        },
      ),
    );
    await _goToActivityPage(tester);
    expect(find.text('Install'), findsOneWidget);

    await tester.tap(find.byKey(DiaryIntroDialogKeys.healthActionButton));
    await tester.pumpAndSettle();
    expect(pressedCount, 1);

    await _pumpIntroDialog(
      tester,
      healthAction: const DiaryIntroHealthAction(
        accessState: HealthDataAccessState.historyRequired,
        hasConnectionError: false,
        onPressed: _noop,
      ),
    );
    await _goToActivityPage(tester);
    expect(find.text('Allow'), findsOneWidget);

    await _pumpIntroDialog(
      tester,
      healthAction: const DiaryIntroHealthAction(
        accessState: HealthDataAccessState.permissionRequired,
        hasConnectionError: true,
        onPressed: _noop,
      ),
    );
    await _goToActivityPage(tester);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('intro activity page renders every activity profile label', (
    tester,
  ) async {
    const cases = [
      (CalorieActivityLevelOption.none, 'Sedentary'),
      (CalorieActivityLevelOption.medium, 'Moderately active'),
      (CalorieActivityLevelOption.high, 'Very active'),
      (CalorieActivityLevelOption.extreme, 'Extremely active'),
    ];

    for (final (option, label) in cases) {
      await _pumpIntroDialog(tester, activityLevelOption: option);
      await _goToActivityPage(tester);

      expect(find.textContaining(label), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
}

Future<void> _pumpIntroDialog(
  WidgetTester tester, {
  DiaryIntroHealthAction? healthAction,
  CalorieActivityLevelOption activityLevelOption =
      CalorieActivityLevelOption.low,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DiaryIntroDialog(
          data: _introData(activityLevelOption),
          healthAction: healthAction,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _goToActivityPage(WidgetTester tester) async {
  for (var index = 0; index < 5; index += 1) {
    await tester.tap(find.byKey(DiaryIntroDialogKeys.nextButton));
    await tester.pumpAndSettle();
  }
}

DiaryIntroData _introData(CalorieActivityLevelOption activityLevelOption) {
  return DiaryIntroData(
    goalMode: CalorieGoalMode.lose,
    maintenanceKcal: 1800,
    dailyAdjustmentKcal: 500,
    targetKcal: 1300,
    goalSpeedKgPerWeek: 0.5,
    activityLevelOption: activityLevelOption,
    expectedActivityKcal: 250,
  );
}

void _noop() {}
