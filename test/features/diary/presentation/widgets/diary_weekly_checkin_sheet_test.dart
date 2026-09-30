import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_demo_data.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_sheet/diary_weekly_checkin_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_result.dart';
import 'package:yamt/l10n/app_localizations.dart';

final _today = DateTime(2026, 4, 20);

void main() {
  testWidgets('ready check-in walks the three steps and returns apply', (
    tester,
  ) async {
    final results = <DiaryWeeklyCheckInSheetResult?>[];
    await tester.pumpWidget(
      _App(checkInData: _readyData(), onResult: results.add),
    );
    await _openSheet(tester);

    expect(find.text('Week done'), findsOneWidget);
    expect(
      find.byKey(DiaryWeeklyCheckInSheetKeys.useMeasuredChoice),
      findsOneWidget,
    );

    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton));
    await tester.pumpAndSettle();
    expect(find.text('When do you train?'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await _tapVisible(
      tester,
      find.byKey(DiaryWeeklyCheckInSheetKeys.trainingDay(1)),
    );
    await tester.pumpAndSettle();
    expect(find.text('4'), findsOneWidget);

    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton));
    await tester.pumpAndSettle();
    expect(find.text('Daily goal on average'.toUpperCase()), findsOneWidget);
    expect(find.text('measured'), findsOneWidget);

    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.startWeekButton));
    await tester.pumpAndSettle();

    expect(results, hasLength(1));
    expect(results.single!.action, DiaryWeeklyCheckInSheetAction.apply);
    expect(results.single!.trainingDays, hasLength(4));
  });

  testWidgets('keeping the previous TDEE returns reject', (tester) async {
    final results = <DiaryWeeklyCheckInSheetResult?>[];
    await tester.pumpWidget(
      _App(checkInData: _readyData(), onResult: results.add),
    );
    await _openSheet(tester);

    await _tapVisible(
      tester,
      find.byKey(DiaryWeeklyCheckInSheetKeys.keepPreviousChoice),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton));
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.byKey(DiaryWeeklyCheckInSheetKeys.noSessionButton),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton));
    await tester.pumpAndSettle();
    expect(find.text('previous'), findsOneWidget);

    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.startWeekButton));
    await tester.pumpAndSettle();

    expect(results.single!.action, DiaryWeeklyCheckInSheetAction.reject);
    expect(results.single!.trainingDays, isEmpty);
  });

  testWidgets('later and change goal close the sheet with their action', (
    tester,
  ) async {
    final results = <DiaryWeeklyCheckInSheetResult?>[];
    await tester.pumpWidget(
      _App(checkInData: _readyData(), onResult: results.add),
    );

    await _openSheet(tester);
    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.laterButton));
    await tester.pumpAndSettle();

    await _openSheet(tester);
    await _tapVisible(
      tester,
      find.byKey(DiaryWeeklyCheckInSheetKeys.changeGoalButton),
    );
    await tester.pumpAndSettle();

    expect(results.map((result) => result?.action), [
      DiaryWeeklyCheckInSheetAction.later,
      DiaryWeeklyCheckInSheetAction.newGoal,
    ]);
    expect(results.map((result) => result?.trainingDays), [null, null]);
  });

  testWidgets('blocked check-in offers the missing weight and later', (
    tester,
  ) async {
    final results = <DiaryWeeklyCheckInSheetResult?>[];
    await tester.pumpWidget(
      _App(
        checkInData: calorieWeeklyCheckInDemoData(today: _today, blocked: true),
        onResult: results.add,
      ),
    );
    await _openSheet(tester);

    expect(find.text('Check-in needs data'), findsOneWidget);
    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton), findsNothing);

    await tester.tap(
      find.byKey(DiaryWeeklyCheckInSheetKeys.trackMissingWeightButton),
    );
    await tester.pumpAndSettle();

    expect(
      results.single!.action,
      DiaryWeeklyCheckInSheetAction.trackMissingWeight,
    );
  });

  testWidgets('reached goal only offers a new goal and cannot be dismissed', (
    tester,
  ) async {
    final results = <DiaryWeeklyCheckInSheetResult?>[];
    await tester.pumpWidget(
      _App(checkInData: _readyData(), onResult: results.add, goalReached: true),
    );
    await _openSheet(tester);

    expect(find.text('Congratulations!'), findsOneWidget);
    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.laterButton), findsNothing);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);
    expect(results, isEmpty);

    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.newGoalButton));
    await tester.pumpAndSettle();

    expect(results.single!.action, DiaryWeeklyCheckInSheetAction.newGoal);
  });
}

DiaryWeeklyCheckInData _readyData() =>
    calorieWeeklyCheckInDemoData(today: _today);

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

Future<void> _openSheet(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.tap(find.byKey(_openSheetButtonKey));
  await tester.pumpAndSettle();
}

const _openSheetButtonKey = ValueKey<String>('open-sheet');

class _App extends StatelessWidget {
  const new({
    required this.checkInData,
    required this.onResult,
    this.goalReached = false,
  });

  final DiaryWeeklyCheckInData checkInData;
  final ValueChanged<DiaryWeeklyCheckInSheetResult?> onResult;
  final bool goalReached;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        diaryWeeklyCheckInPlanProvider.overrideWith(
          (ref) async => calorieWeeklyCheckInDemoPlan(
            today: _today,
            macroSettings: const MacroGoalSettings(),
            profile: null,
          ),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                key: _openSheetButtonKey,
                onPressed: () async {
                  onResult(
                    await showDiaryWeeklyCheckInSheet(
                      context,
                      checkInData: checkInData,
                      goalReached: goalReached,
                    ),
                  );
                },
                child: const Text('Open sheet'),
              );
            },
          ),
        ),
      ),
    );
  }
}
