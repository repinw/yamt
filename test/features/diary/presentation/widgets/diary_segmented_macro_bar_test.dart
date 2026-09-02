import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_segmented_macro_bar.dart';

void main() {
  group('DiarySegmentedMacroBar', () {
    List<double?> getWidthFactors(WidgetTester tester) {
      return tester
          .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .map((box) => box.widthFactor)
          .toList();
    }

    Future<void> pumpBar(
      WidgetTester tester, {
      required double progress,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: DiarySegmentedMacroBar(
                  progress: progress,
                  color: Colors.blue,
                  trackColor: Colors.grey,
                  isDark: false,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders exactly 4 segments with 0 fill when progress is 0.0', (
      tester,
    ) async {
      await pumpBar(tester, progress: 0);

      final factors = getWidthFactors(tester);
      expect(factors, [0.0, 0.0, 0.0, 0.0]);
    });

    testWidgets('fills first segment completely at 0.25 progress', (
      tester,
    ) async {
      await pumpBar(tester, progress: 0.25);

      final factors = getWidthFactors(tester);
      expect(factors, [1.0, 0.0, 0.0, 0.0]);
    });

    testWidgets('fills first two segments at 0.50 progress', (
      tester,
    ) async {
      await pumpBar(tester, progress: 0.50);

      final factors = getWidthFactors(tester);
      expect(factors, [1.0, 1.0, 0.0, 0.0]);
    });

    testWidgets('fills first three segments at 0.75 progress', (
      tester,
    ) async {
      await pumpBar(tester, progress: 0.75);

      final factors = getWidthFactors(tester);
      expect(factors, [1.0, 1.0, 1.0, 0.0]);
    });

    testWidgets('fills all 4 segments at 1.0 progress', (
      tester,
    ) async {
      await pumpBar(tester, progress: 1);

      final factors = getWidthFactors(tester);
      expect(factors, [1.0, 1.0, 1.0, 1.0]);
    });

    testWidgets('partially fills segment for intermediate progress (0.125)', (
      tester,
    ) async {
      await pumpBar(tester, progress: 0.125);

      final factors = getWidthFactors(tester);
      // 0.125 is halfway through first segment (0.0 to 0.25)
      expect(factors[0], closeTo(0.5, 0.001));
      expect(factors[1], 0.0);
      expect(factors[2], 0.0);
      expect(factors[3], 0.0);
    });

    testWidgets('clamps all segments to 1.0 when progress exceeds 1.0', (
      tester,
    ) async {
      await pumpBar(tester, progress: 1.8);

      final factors = getWidthFactors(tester);
      expect(factors, [1.0, 1.0, 1.0, 1.0]);
    });

    testWidgets('clamps all segments to 0.0 when progress is negative', (
      tester,
    ) async {
      await pumpBar(tester, progress: -0.5);

      final factors = getWidthFactors(tester);
      expect(factors, [0.0, 0.0, 0.0, 0.0]);
    });
  });
}
