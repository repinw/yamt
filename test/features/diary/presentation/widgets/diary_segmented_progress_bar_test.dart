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
