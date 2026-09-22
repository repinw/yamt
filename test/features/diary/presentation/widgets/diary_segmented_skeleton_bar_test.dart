import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_segmented_skeleton_bar.dart';

void main() {
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
