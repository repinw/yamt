import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart'
    show DiaryWeeklyCheckInData;
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_dialog/diary_weekly_checkin_dialog.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_dialog/diary_weekly_checkin_dialog_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('ready dialog returns later and apply actions', (tester) async {
    final results = <DiaryWeeklyCheckInDialogAction?>[];

    await tester.pumpWidget(
      _App(
        checkInData: _checkInData(lowConfidence: true),
        onResult: results.add,
      ),
    );

    await _openDialog(tester);

    expect(find.byKey(DiaryWeeklyCheckInDialogKeys.dialog), findsOneWidget);
    expect(
      find.text('Low confidence: only start and end weights were available.'),
      findsOneWidget,
    );
    expect(
      find.byKey(DiaryWeeklyCheckInDialogKeys.openTrendsButton),
      findsNothing,
    );

    await tester.tap(find.byKey(DiaryWeeklyCheckInDialogKeys.laterButton));
    await tester.pumpAndSettle();

    expect(results, [DiaryWeeklyCheckInDialogAction.later]);

    await _openDialog(tester);
    await tester.tap(find.byKey(DiaryWeeklyCheckInDialogKeys.applyButton));
    await tester.pumpAndSettle();

    expect(results, [
      DiaryWeeklyCheckInDialogAction.later,
      DiaryWeeklyCheckInDialogAction.apply,
    ]);
  });

  testWidgets('blocked weight dialog returns open health trends action', (
    tester,
  ) async {
    final results = <DiaryWeeklyCheckInDialogAction?>[];

    await tester.pumpWidget(
      _App(
        checkInData: _checkInData(
          blockedReason:
              CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight,
          missingWeightDays: [DateTime(2026, 4)],
        ),
        onResult: results.add,
      ),
    );

    await _openDialog(tester);

    expect(
      find.byKey(DiaryWeeklyCheckInDialogKeys.openTrendsButton),
      findsOneWidget,
    );
    expect(find.byKey(DiaryWeeklyCheckInDialogKeys.applyButton), findsNothing);

    await tester.tap(
      find.byKey(DiaryWeeklyCheckInDialogKeys.openTrendsButton),
    );
    await tester.pumpAndSettle();

    expect(results, [DiaryWeeklyCheckInDialogAction.openHealthTrends]);
  });
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(_openDialogButtonKey));
  await tester.pumpAndSettle();
}

const _openDialogButtonKey = ValueKey<String>('open-dialog');

class _App extends StatelessWidget {
  const _App({
    required this.checkInData,
    required this.onResult,
  });

  final DiaryWeeklyCheckInData checkInData;
  final ValueChanged<DiaryWeeklyCheckInDialogAction?> onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              key: _openDialogButtonKey,
              onPressed: () async {
                final result = await showDiaryWeeklyCheckInDialog(
                  context,
                  checkInData: checkInData,
                );
                onResult(result);
              },
              child: const Text('Open dialog'),
            );
          },
        ),
      ),
    );
  }
}

DiaryWeeklyCheckInData _checkInData({
  CalorieWeeklyCheckInBlockedReason? blockedReason,
  List<DateTime> missingWeightDays = const <DateTime>[],
  bool lowConfidence = false,
}) {
  final pending = PendingCalorieGoalWeeklyCheckIn(
    windowStartDate: DateTime(2026, 4),
    windowEndDate: DateTime(2026, 4, 6),
    dueDate: DateTime(2026, 4, 7),
  );

  return DiaryWeeklyCheckInData(
    pendingWeeklyCheckIn: pending,
    shouldAutoOpen: true,
    days: const <CalorieWeeklyCheckInWindowDay>[],
    calculation: blockedReason == null
        ? const CalorieWeeklyCheckInCalculation(
            trendWeightChangePerDay: -0.05,
            averageIntakeKcal: 2150,
            measuredTrueTdeeKcal: 2500,
            calculatedTrueTdeeKcal: 2450,
            newGoalKcal: 2200,
            lastWeekAverageActiveKcal: 300,
            todayActiveKcal: 350,
            activityDeltaKcal: 25,
            dynamicGoalTodayKcal: 2225,
          )
        : null,
    blockedReason: blockedReason,
    missingIntakeDays: const <DateTime>[],
    missingWeightDays: missingWeightDays,
    freshness: CalorieLearnedTdeeFreshness.fresh,
    latestLearnedTdeeAt: null,
    lowConfidence: lowConfidence,
  );
}
