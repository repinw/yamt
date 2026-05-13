import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/calorie_page_actions.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('skipped-intake snackbar shows save failure', (tester) async {
    final context = await _pumpSnackBarHarness(tester);

    showSkippedCalorieIntakeSaveFailedSnackBar(context);
    await tester.pump();

    expect(find.text('Could not save calorie goal.'), findsOneWidget);
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
