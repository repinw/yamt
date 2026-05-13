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
