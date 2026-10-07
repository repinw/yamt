import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/core/widgets/app_snack_bar_view.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  Future<ScaffoldMessengerState> pumpMessenger(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    late ScaffoldMessengerState messenger;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              messenger = ScaffoldMessenger.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return messenger;
  }

  testWidgets('shows a success snack bar with the check icon', (tester) async {
    final messenger = await pumpMessenger(tester);

    messenger.showAppSnackBar('Saved');
    await tester.pump();

    expect(find.text('Saved'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('sits at the top of the screen', (tester) async {
    final messenger = await pumpMessenger(tester);

    messenger.showAppSnackBar('Saved');
    await tester.pumpAndSettle();

    final screen = tester.getSize(find.byType(MaterialApp));
    expect(
      tester.getRect(find.byType(AppSnackBarView)).bottom,
      lessThan(screen.height / 2),
    );
  });

  testWidgets('a messenger inside a route shows it in the root overlay', (
    tester,
  ) async {
    await pumpMessenger(tester);
    late ScaffoldMessengerState inner;
    Navigator.of(tester.element(find.byType(Scaffold)))
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ScaffoldMessenger(
              child: Builder(
                builder: (context) {
                  inner = ScaffoldMessenger.of(context);
                  return const Scaffold();
                },
              ),
            ),
          ),
        )
        .ignore();
    await tester.pumpAndSettle();

    inner.showAppSnackBar('Saved');
    await tester.pump();

    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('replaces the current snack bar and shows the error style', (
    tester,
  ) async {
    final messenger = await pumpMessenger(tester);

    final first = messenger.showAppSnackBar('First');
    await tester.pump();
    messenger.showAppSnackBar('Failed', tone: AppSnackBarTone.error);
    await tester.pumpAndSettle();

    expect(find.text('First'), findsNothing);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(await first.closed, isFalse);
  });

  testWidgets('undo runs the callback and closes as an action', (tester) async {
    final messenger = await pumpMessenger(tester);
    var undone = false;

    final shown = messenger.showAppSnackBar(
      'Deleted',
      onUndo: () async => undone = true,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(undone, isTrue);
    expect(await shown.closed, isTrue);
    expect(find.text('Deleted'), findsNothing);
    expect(find.text('Could not undo.'), findsNothing);
  });

  testWidgets('a long message wraps beside the undo action', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final messenger = await pumpMessenger(tester, locale: const Locale('de'));

    messenger.showAppSnackBar(
      'Die Mahlzeit konnte nicht zurück in den Vorrat gelegt werden.',
      onUndo: () async => true,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Rückgängig'), findsOneWidget);
  });

  testWidgets('a failed undo shows the failure snack bar', (tester) async {
    final messenger = await pumpMessenger(tester);

    messenger.showAppSnackBar('Deleted', onUndo: () async => false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('Could not undo.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('hides itself after the timeout, also with an action', (
    tester,
  ) async {
    final messenger = await pumpMessenger(tester);

    final shown = messenger.showAppSnackBar(
      'Deleted',
      onUndo: () async => true,
    );
    await tester.pumpAndSettle();
    expect(find.text('Deleted'), findsOneWidget);

    await tester.pump(AppDurations.snackBar);
    await tester.pumpAndSettle();

    expect(find.text('Deleted'), findsNothing);
    expect(await shown.closed, isFalse);
  });

  testWidgets('a swipe up closes it', (tester) async {
    final messenger = await pumpMessenger(tester);

    final shown = messenger.showAppSnackBar('Saved');
    await tester.pumpAndSettle();
    await tester.fling(find.text('Saved'), const Offset(0, -200), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Saved'), findsNothing);
    expect(await shown.closed, isFalse);
  });

  testWidgets('hideAppSnackBar removes it right away', (tester) async {
    final messenger = await pumpMessenger(tester);

    final shown = messenger.showAppSnackBar('Saved');
    await tester.pumpAndSettle();
    messenger.hideAppSnackBar();
    await tester.pump();

    expect(find.text('Saved'), findsNothing);
    expect(await shown.closed, isFalse);
  });

  testWidgets('staysUntilClosed keeps it after the timeout', (tester) async {
    final messenger = await pumpMessenger(tester);

    messenger.showAppSnackBar('Update', staysUntilClosed: true);
    await tester.pumpAndSettle();
    await tester.pump(AppDurations.snackBar * 2);
    await tester.pumpAndSettle();

    expect(find.text('Update'), findsOneWidget);
  });

  testWidgets('closed completes when the app goes away', (tester) async {
    final messenger = await pumpMessenger(tester);

    final shown = messenger.showAppSnackBar('Saved');
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());

    expect(await shown.closed, isFalse);
  });

  testWidgets('with a screen reader on, a card with an action stays', (
    tester,
  ) async {
    final messenger = await pumpMessenger(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    messenger.showAppSnackBar('Deleted', onUndo: () async => true);
    await tester.pumpAndSettle();
    await tester.pump(AppDurations.snackBar * 2);
    await tester.pumpAndSettle();
    expect(find.text('Deleted'), findsOneWidget);

    messenger.showAppSnackBar('Saved');
    await tester.pumpAndSettle();
    await tester.pump(AppDurations.snackBar);
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
  });
}
