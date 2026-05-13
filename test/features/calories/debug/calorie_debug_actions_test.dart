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
      find.text('Printed calorie debug table (3 rows).'),
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

    expect(find.text('Could not print calorie debug table.'), findsOneWidget);
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
