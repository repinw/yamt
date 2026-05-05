import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_live_overview_dialogs.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('simple dialog calls route callback and closes', (tester) async {
    var routeReadyCount = 0;

    await _pumpDialogLauncher(
      tester,
      onPressed: (context) {
        unawaited(
          showBurnWeekSimpleDialog(
            context: context,
            title: 'Mock warning',
            message: 'Mock body',
            onRouteReady: (_, _) {
              routeReadyCount += 1;
            },
          ),
        );
      },
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(routeReadyCount, 1);
    expect(find.text('Mock warning'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('use heart dialog returns add action', (tester) async {
    BurnWeekLiveHeartAction? result;

    await _pumpDialogLauncher(
      tester,
      onPressed: (context) {
        unawaited(
          showBurnWeekUseHeartDialog(context: context, dayKcal: 2000).then((
            action,
          ) {
            result = action;
          }),
        );
      },
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use heart'));
    await tester.pumpAndSettle();

    expect(result, BurnWeekLiveHeartAction.add);
  });

  testWidgets('below recover dialog returns each selected action', (
    tester,
  ) async {
    BurnWeekLiveBelowZoneAction? eatMoreResult;
    BurnWeekLiveBelowZoneAction? heartResult;

    await _pumpDialogLauncher(
      tester,
      onPressed: (context) {
        unawaited(
          showBurnWeekBelowRecoverDialog(
            context: context,
            hasHearts: true,
          ).then((action) {
            eatMoreResult = action;
          }),
        );
      },
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eat more'));
    await tester.pumpAndSettle();

    expect(eatMoreResult, BurnWeekLiveBelowZoneAction.eatMore);

    await _pumpDialogLauncher(
      tester,
      onPressed: (context) {
        unawaited(
          showBurnWeekBelowRecoverDialog(
            context: context,
            hasHearts: true,
          ).then((action) {
            heartResult = action;
          }),
        );
      },
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use heart'));
    await tester.pumpAndSettle();

    expect(heartResult, BurnWeekLiveBelowZoneAction.useHeart);
  });

  testWidgets('below recover dialog hides heart action without hearts', (
    tester,
  ) async {
    await _pumpDialogLauncher(
      tester,
      onPressed: (context) {
        unawaited(
          showBurnWeekBelowRecoverDialog(
            context: context,
            hasHearts: false,
          ),
        );
      },
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Use heart'), findsNothing);
    expect(find.textContaining('No hearts left'), findsOneWidget);
  });

  testWidgets('needs-heart dialogs return confirmed choice', (tester) async {
    bool? belowResult;
    bool? aboveResult;

    await _pumpDialogLauncher(
      tester,
      onPressed: (context) {
        unawaited(
          showBurnWeekBelowNeedsHeartDialog(context).then((confirmed) {
            belowResult = confirmed;
          }),
        );
      },
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();

    expect(belowResult, isFalse);

    await _pumpDialogLauncher(
      tester,
      onPressed: (context) {
        unawaited(
          showBurnWeekAboveNeedsHeartDialog(context).then((confirmed) {
            aboveResult = confirmed;
          }),
        );
      },
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(aboveResult, isTrue);
  });

  testWidgets('run limit dialog returns run limit actions', (tester) async {
    BurnWeekRunLimitAction? continueResult;
    BurnWeekRunLimitAction? restartResult;

    await _pumpDialogLauncher(
      tester,
      onPressed: (context) {
        unawaited(
          showBurnWeekRunLimitDialog(
            context: context,
            message: 'Cannot recover this week.',
          ).then((action) {
            continueResult = action;
          }),
        );
      },
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue anyway'));
    await tester.pumpAndSettle();

    expect(continueResult, BurnWeekRunLimitAction.continueRun);

    await _pumpDialogLauncher(
      tester,
      onPressed: (context) {
        unawaited(
          showBurnWeekRunLimitDialog(
            context: context,
            message: 'Cannot recover this week.',
          ).then((action) {
            restartResult = action;
          }),
        );
      },
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start new run'));
    await tester.pumpAndSettle();

    expect(restartResult, BurnWeekRunLimitAction.startNewRun);
  });

  testWidgets('details dialog maps Burn Week data into shared rows', (
    tester,
  ) async {
    await _pumpDialogLauncher(
      tester,
      onPressed: (context) {
        unawaited(
          showBurnWeekDetailsDialog(
            context: context,
            data: const BurnWeekLiveDetailsData(
              actualText: '123 kcal',
              targetText: '456 kcal',
              dailyGoalText: '2000 kcal',
              weeklyGoalText: '14000 kcal',
              currentTimeLabel: 'day 3 noon',
              weekRatioText: '0.42',
              targetFormulaText: 'goal x time',
              weekEatenSoFarText: '4000 kcal',
              plannedLaterTodayText: '300 kcal',
              todayBudgetText: '2100 kcal',
              todayFoodText: '900 kcal',
              todayLeftText: '1200 kcal',
              weekActivityBonusText: '80 kcal',
              weekCarryoverText: '-40 kcal',
              previousWeekOverflowText: '20 kcal',
              weekRemainingAfterFoodText: '10000 kcal',
              safeMinText: '1700 kcal',
              safeMaxText: '2300 kcal',
              starsHeartsText: '2 / 1',
              heartCreditText: '0 kcal',
            ),
          ),
        );
      },
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Burn Week details'), findsOneWidget);
    expect(find.text('123 kcal'), findsOneWidget);
    expect(find.text('456 kcal'), findsOneWidget);
    expect(_findRichTextContaining('Daily goal: 2000 kcal'), findsOneWidget);
    expect(_findRichTextContaining('Stars / Hearts: 2 / 1'), findsOneWidget);
    expect(
      _findRichTextContaining('Safe zone: 1700 kcal - 2300 kcal'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpDialogLauncher(
  WidgetTester tester, {
  required ValueChanged<BuildContext> onPressed,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () => onPressed(context),
              child: const Text('Open'),
            );
          },
        ),
      ),
    ),
  );
}

Finder _findRichTextContaining(String text) {
  return find.byWidgetPredicate((widget) {
    return widget is RichText && widget.text.toPlainText().contains(text);
  });
}
