import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_nutrition_macro_row.dart';

void main() {
  group('DiaryNutritionMacroRow', () {
    final numberFormat = NumberFormat.decimalPattern('en');

    Future<void> pumpRow(
      WidgetTester tester, {
      required String label,
      required double current,
      required double target,
      String unit = 'g',
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 350,
                child: DiaryNutritionMacroRow(
                  label: label,
                  current: current,
                  target: target,
                  color: Colors.green,
                  numberFormat: numberFormat,
                  unit: unit,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders remaining grams when intake is under target', (
      tester,
    ) async {
      await pumpRow(
        tester,
        label: 'Protein',
        current: 45,
        target: 100,
      );

      // 100 - 45 = 55g remaining
      expect(find.text('55g'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(
        find.textContaining('45 / 100g', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('renders 0g remaining when intake equals target', (
      tester,
    ) async {
      await pumpRow(
        tester,
        label: 'Carbs',
        current: 150,
        target: 150,
      );

      expect(find.text('0g'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
      expect(
        find.textContaining('150 / 150g', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('renders plus indicator (+Xg) when intake exceeds target', (
      tester,
    ) async {
      await pumpRow(
        tester,
        label: 'Fat',
        current: 85,
        target: 70,
      );

      // 85 - 70 = +15g overage
      expect(find.text('+15g'), findsOneWidget);
      expect(find.text('Fat'), findsOneWidget);
      expect(
        find.textContaining('85 / 70g', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('handles zero target safely without division by zero', (
      tester,
    ) async {
      await pumpRow(
        tester,
        label: 'Protein',
        current: 0,
        target: 0,
      );

      expect(find.text('0g'), findsOneWidget);
      expect(
        find.textContaining('0 / 0g', findRichText: true),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
