import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/calorie_health_trends_page_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_health_weight_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _buildTestApp({
  required Future<void> Function(BuildContext context) onOpen,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return TextButton(
            onPressed: () => onOpen(context),
            child: const Text('Open'),
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets('dialog validates and saves manual weight', (tester) async {
    double? savedWeight;

    await tester.pumpWidget(
      _buildTestApp(
        onOpen: (context) {
          return showCalorieHealthWeightDialog(
            context: context,
            dayLabel: 'Mar 20, 2026',
            initialWeightKg: null,
            hasManualWeight: false,
            onSaveWeight: (weightKg) async {
              savedWeight = weightKg;
              return true;
            },
            onClearWeight: () async => true,
          );
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(CalorieHealthTrendsPageKeys.weightDialogSaveButton),
    );
    await tester.pumpAndSettle();
    expect(find.text('Please enter your weight.'), findsOneWidget);

    await tester.enterText(
      find.byKey(CalorieHealthTrendsPageKeys.weightDialogField),
      '71,4',
    );
    await tester.tap(
      find.byKey(CalorieHealthTrendsPageKeys.weightDialogSaveButton),
    );
    await tester.pumpAndSettle();

    expect(savedWeight, 71.4);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('dialog shows snackbar when save fails', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        onOpen: (context) {
          return showCalorieHealthWeightDialog(
            context: context,
            dayLabel: 'Mar 20, 2026',
            initialWeightKg: null,
            hasManualWeight: false,
            onSaveWeight: (weightKg) async => false,
            onClearWeight: () async => true,
          );
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(CalorieHealthTrendsPageKeys.weightDialogField),
      '71.4',
    );
    await tester.tap(
      find.byKey(CalorieHealthTrendsPageKeys.weightDialogSaveButton),
    );
    await tester.pump();

    expect(find.text('Could not save weight.'), findsOneWidget);
  });

  testWidgets('dialog exposes clear action for manual override', (
    tester,
  ) async {
    var clearCallCount = 0;

    await tester.pumpWidget(
      _buildTestApp(
        onOpen: (context) {
          return showCalorieHealthWeightDialog(
            context: context,
            dayLabel: 'Mar 20, 2026',
            initialWeightKg: 71.2,
            hasManualWeight: true,
            onSaveWeight: (weightKg) async => true,
            onClearWeight: () async {
              clearCallCount += 1;
              return true;
            },
          );
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('71.2'), findsOneWidget);
    await tester.tap(
      find.byKey(CalorieHealthTrendsPageKeys.weightDialogClearButton),
    );
    await tester.pumpAndSettle();

    expect(clearCallCount, 1);
  });

  testWidgets('dialog shows snackbar when clear fails', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        onOpen: (context) {
          return showCalorieHealthWeightDialog(
            context: context,
            dayLabel: 'Mar 20, 2026',
            initialWeightKg: 71.2,
            hasManualWeight: true,
            onSaveWeight: (weightKg) async => true,
            onClearWeight: () async => false,
          );
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(CalorieHealthTrendsPageKeys.weightDialogClearButton),
    );
    await tester.pump();

    expect(find.text('Could not clear manual weight.'), findsOneWidget);
  });

  testWidgets('dialog cancel does not call save or clear callbacks', (
    tester,
  ) async {
    var saveCallCount = 0;
    var clearCallCount = 0;

    await tester.pumpWidget(
      _buildTestApp(
        onOpen: (context) {
          return showCalorieHealthWeightDialog(
            context: context,
            dayLabel: 'Mar 20, 2026',
            initialWeightKg: 71.2,
            hasManualWeight: true,
            onSaveWeight: (weightKg) async {
              saveCallCount += 1;
              return true;
            },
            onClearWeight: () async {
              clearCallCount += 1;
              return true;
            },
          );
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(saveCallCount, 0);
    expect(clearCallCount, 0);
  });
}
