import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
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
    expect(find.byType(SnackBarAction), findsNothing);
  });

  testWidgets('replaces the current snack bar and shows the error style', (
    tester,
  ) async {
    final messenger = await pumpMessenger(tester);

    messenger.showAppSnackBar('First');
    await tester.pump();
    messenger.showAppSnackBar('Failed', tone: AppSnackBarTone.error);
    await tester.pumpAndSettle();

    expect(find.text('First'), findsNothing);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('undo runs the callback', (tester) async {
    final messenger = await pumpMessenger(tester);
    var undone = false;

    messenger.showAppSnackBar('Deleted', onUndo: () async => undone = true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(undone, isTrue);
    expect(find.text('Could not undo.'), findsNothing);
  });

  testWidgets('the undo action keeps the snack bar one row high', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final messenger = await pumpMessenger(tester, locale: const Locale('de'));

    messenger.showAppSnackBar('Gone');
    await tester.pumpAndSettle();
    final plainHeight = tester.getSize(find.byType(SnackBar)).height;
    messenger.showAppSnackBar('Gone', onUndo: () async => true);
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(SnackBar)).height, plainHeight);
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

    messenger.showAppSnackBar('Deleted', onUndo: () async => true);
    await tester.pumpAndSettle();
    expect(find.text('Deleted'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Deleted'), findsNothing);
  });
}
