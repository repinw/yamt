import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_eating_window_dialog.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _buildHarness({
  required Future<bool> Function(int startMinuteOfDay, int endMinuteOfDay)
  onSaveEatingWindow,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return Center(
            child: FilledButton(
              onPressed: () {
                showCalorieEatingWindowDialog(
                  context: context,
                  initialStartMinuteOfDay: 6 * 60,
                  initialEndMinuteOfDay: 22 * 60,
                  onSaveEatingWindow: onSaveEatingWindow,
                );
              },
              child: const Text('Open'),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets('save failure shows eating window error message', (tester) async {
    await tester.pumpWidget(
      _buildHarness(onSaveEatingWindow: (_, _) async => false),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CalorieEatingWindowDialogKeys.saveButton));
    await tester.pumpAndSettle();

    expect(find.text('Could not update the eating window.'), findsOneWidget);
  });
}
