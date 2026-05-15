import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/widgets/weight_entry_dialog.dart';

void main() {
  const fieldKey = Key('weight-field');
  const clearButtonKey = Key('weight-clear');
  const saveButtonKey = Key('weight-save');
  const labels = WeightEntryDialogLabels(
    title: 'Weight',
    fieldLabel: 'Weight kg',
    emptyErrorText: 'Please enter a weight',
    invalidErrorText: 'Please enter a valid weight',
    clearActionLabel: 'Clear',
    cancelActionLabel: 'Cancel',
    saveActionLabel: 'Save',
  );
  const keys = WeightEntryDialogKeys(
    fieldKey: fieldKey,
    clearButtonKey: clearButtonKey,
    saveButtonKey: saveButtonKey,
  );

  testWidgets('shows empty error for blank input', (tester) async {
    await _pumpHarness(tester, labels: labels, keys: keys);

    await tester.tap(find.byKey(saveButtonKey));
    await tester.pumpAndSettle();

    expect(find.text(labels.emptyErrorText), findsOneWidget);
  });

  testWidgets('shows invalid error for non-number input', (tester) async {
    await _pumpHarness(tester, labels: labels, keys: keys);

    await tester.enterText(find.byKey(fieldKey), 'abc');
    await tester.tap(find.byKey(saveButtonKey));
    await tester.pumpAndSettle();

    expect(find.text(labels.invalidErrorText), findsOneWidget);
  });

  testWidgets('shows invalid error for negative input', (tester) async {
    await _pumpHarness(tester, labels: labels, keys: keys);

    await tester.enterText(find.byKey(fieldKey), '-5');
    await tester.tap(find.byKey(saveButtonKey));
    await tester.pumpAndSettle();

    expect(find.text(labels.invalidErrorText), findsOneWidget);
  });

  testWidgets('parses comma decimal input and returns save result', (
    tester,
  ) async {
    WeightEntryDialogResult? result;
    await _pumpHarness(
      tester,
      labels: labels,
      keys: keys,
      onResult: (value) => result = value,
    );

    await tester.enterText(find.byKey(fieldKey), '75,5');
    await tester.tap(find.byKey(saveButtonKey));
    await tester.pumpAndSettle();

    expect(result?.action, WeightEntryDialogAction.save);
    expect(result?.weightKg, 75.5);
  });

  testWidgets('clear action returns clear result', (tester) async {
    WeightEntryDialogResult? result;
    await _pumpHarness(
      tester,
      labels: labels,
      keys: keys,
      initialWeightKg: 82.3,
      showClearAction: true,
      onResult: (value) => result = value,
    );

    await tester.tap(find.byKey(clearButtonKey));
    await tester.pumpAndSettle();

    expect(result?.action, WeightEntryDialogAction.clear);
    expect(result?.weightKg, isNull);
  });
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required WeightEntryDialogLabels labels,
  required WeightEntryDialogKeys keys,
  double? initialWeightKg,
  bool showClearAction = false,
  void Function(WeightEntryDialogResult? result)? onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                final result = await showWeightEntryDialog(
                  context: context,
                  labels: labels,
                  initialWeightKg: initialWeightKg,
                  showClearAction: showClearAction,
                  keys: keys,
                );
                onResult?.call(result);
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}
