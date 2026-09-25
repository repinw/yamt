import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_segmented_progress_bar.dart';

void main() {
  group('DiarySegmentedProgressBar', () {
    List<double?> getWidthFactors(WidgetTester tester) {
      return tester
          .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .map((box) => box.widthFactor)
          .toList();
    }

    Future<void> pumpBar(
      WidgetTester tester, {
      required double progress,
      double overflow = 0,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: DiarySegmentedProgressBar(
                  progress: progress,
                  overflow: overflow,
                  color: Colors.blue,
                  trackColor: Colors.grey,
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

    testWidgets('a filled segment covers the full bar height', (tester) async {
      await pumpBar(tester, progress: 0.25);

      final fill = find.descendant(
        of: find.byType(FractionallySizedBox).first,
        matching: find.byType(ColoredBox),
      );
      expect(tester.getSize(fill).height, 6);
    });

    testWidgets('fills first two segments at 0.50 progress', (tester) async {
      await pumpBar(tester, progress: 0.50);

      final factors = getWidthFactors(tester);
      expect(factors, [1.0, 1.0, 0.0, 0.0]);
    });

    testWidgets('fills first three segments at 0.75 progress', (tester) async {
      await pumpBar(tester, progress: 0.75);

      final factors = getWidthFactors(tester);
      expect(factors, [1.0, 1.0, 1.0, 0.0]);
    });

    testWidgets('fills all 4 segments at 1.0 progress', (tester) async {
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

    Finder stripes() => find.descendant(
      of: find.byType(DiarySegmentedProgressBar),
      matching: find.byType(CustomPaint),
    );

    testWidgets('draws no stripes without overflow', (tester) async {
      await pumpBar(tester, progress: 1);

      expect(stripes(), findsNothing);
    });

    testWidgets('stripes only the last segment at 0.25 overflow', (
      tester,
    ) async {
      await pumpBar(tester, progress: 1, overflow: 0.25);

      expect(stripes(), findsOneWidget);
      // Four solid fills, then the striped overlay of the last segment.
      expect(getWidthFactors(tester), [1.0, 1.0, 1.0, 1.0, 1.0]);
      // The stripes fill the full bar height, so they are visible.
      expect(tester.getSize(stripes()).height, 6);
    });

    testWidgets('stripes part of a segment for a partial overflow', (
      tester,
    ) async {
      await pumpBar(tester, progress: 1, overflow: 0.375);

      expect(stripes(), findsNWidgets(2));
      final factors = getWidthFactors(tester);
      // Segment 3 (0.5 to 0.75) is striped from 0.625 on.
      expect(factors[3], closeTo(0.5, 0.001));
      expect(factors.last, 1.0);
    });

    testWidgets('renders custom segment count (7 segments)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              child: DiarySegmentedProgressBar(
                progress: 0.5,
                color: Colors.orange,
                trackColor: Colors.grey,
                segmentCount: 7,
              ),
            ),
          ),
        ),
      );

      final factors = getWidthFactors(tester);
      expect(factors, hasLength(7));
      // 0.5 is 3.5 / 7, so first 3 segments full, 4th half-full, rest empty
      expect(factors[0], 1.0);
      expect(factors[1], 1.0);
      expect(factors[2], 1.0);
      expect(factors[3], closeTo(0.5, 0.001));
      expect(factors[4], 0.0);
      expect(factors[5], 0.0);
      expect(factors[6], 0.0);
    });
  });
}
