import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_segmented_progress_bar.dart';

void main() {
  group('DiarySegmentedProgressBar', () {
    List<double?> getWidthFactors(WidgetTester tester) {
      return tester
          .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .map((box) => box.widthFactor)
          .toList();
    }

    testWidgets('highlights only the newly filled part of each segment', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              child: DiarySegmentedProgressBar(
                progress: 0.75,
                highlightStart: 0.625,
                highlightOpacity: 1,
                color: Colors.orange,
                trackColor: Colors.grey,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      // Two old segments, the third with its right half highlighted,
      // then one empty segment.
      expect(getWidthFactors(tester), [1, 1, 1, 0.5, 0]);
      final highlighted = find.byWidgetPredicate(
        (widget) =>
            widget is Align && widget.alignment == Alignment.centerRight,
      );
      expect(highlighted, findsOneWidget);
    });

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
                child: DiarySegmentedProgressBar(
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
                isDark: false,
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

  group('DiarySegmentedSkeletonBar', () {
    testWidgets('renders requested number of skeleton blocks', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              child: DiarySegmentedSkeletonBar(
                segmentCount: 7,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );

      final blocks = find.byType(MetricSkeletonBlock);
      expect(blocks, findsNWidgets(7));
    });
  });
}
