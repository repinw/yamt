import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/debug/calorie_debug_action_controller.dart';
import 'package:yamt/features/calories/debug/calorie_debug_actions.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('debug dump snackbar shows success message', (tester) async {
    final context = await _pumpSnackBarHarness(tester);

    showCalorieDebugDumpResultSnackBar(
      context: context,
      result: const CalorieDebugDumpPrintSuccess(rowCount: 3),
    );
    await tester.pump();

    expect(
      find.text('Downloaded calorie debug TXT (3 rows).'),
      findsOneWidget,
    );
  });

  testWidgets('debug dump snackbar shows canceled message', (tester) async {
    final context = await _pumpSnackBarHarness(tester);

    showCalorieDebugDumpResultSnackBar(
      context: context,
      result: const CalorieDebugDumpPrintCanceled(),
    );
    await tester.pump();

    expect(
      find.text('Calorie debug TXT download canceled.'),
      findsOneWidget,
    );
  });

  testWidgets('debug dump snackbar shows failure message', (tester) async {
    final context = await _pumpSnackBarHarness(tester);

    showCalorieDebugDumpResultSnackBar(
      context: context,
      result: const CalorieDebugDumpPrintFailure(),
    );
    await tester.pump();

    expect(find.text('Could not download calorie debug TXT.'), findsOneWidget);
  });

  testWidgets('settings debug dump snackbar shows success message', (
    tester,
  ) async {
    final context = await _pumpSnackBarHarness(tester);

    showCalorieSettingsDebugDumpResultSnackBar(
      context: context,
      result: const CalorieSettingsDebugDumpPrintSuccess(entryCount: 2),
    );
    await tester.pump();

    expect(
      find.text('Printed calorie settings debug dump (2 goal entries).'),
      findsOneWidget,
    );
  });

  testWidgets('settings debug dump snackbar shows failure message', (
    tester,
  ) async {
    final context = await _pumpSnackBarHarness(tester);

    showCalorieSettingsDebugDumpResultSnackBar(
      context: context,
      result: const CalorieSettingsDebugDumpPrintFailure(),
    );
    await tester.pump();

    expect(
      find.text('Could not print calorie settings debug dump.'),
      findsOneWidget,
    );
  });

  testWidgets('weekly check-in debug dump snackbar shows success message', (
    tester,
  ) async {
    final context = await _pumpSnackBarHarness(tester);

    showCalorieWeeklyCheckInDebugDumpResultSnackBar(
      context: context,
      result: const CalorieWeeklyCheckInDebugDumpPrintSuccess(),
    );
    await tester.pump();

    expect(find.text('Printed weekly check-in debug dump.'), findsOneWidget);
  });

  testWidgets('weekly check-in debug dump snackbar shows failure message', (
    tester,
  ) async {
    final context = await _pumpSnackBarHarness(tester);

    showCalorieWeeklyCheckInDebugDumpResultSnackBar(
      context: context,
      result: const CalorieWeeklyCheckInDebugDumpPrintFailure(),
    );
    await tester.pump();

    expect(
      find.text('Could not print weekly check-in debug dump.'),
      findsOneWidget,
    );
  });
}

Future<BuildContext> _pumpSnackBarHarness(WidgetTester tester) async {
  late BuildContext capturedContext;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return capturedContext;
}
