import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_animated_macro_bar.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_segmented_progress_bar.dart';

void main() {
  Future<void> pumpBar(WidgetTester tester, {required double current}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: DiaryAnimatedMacroBar(
              current: current,
              target: 100,
              color: Colors.blue,
              trackColor: Colors.grey,
              handoffTag: #macro,
            ),
          ),
        ),
      ),
    );
  }

  DiarySegmentedProgressBar bar(WidgetTester tester) =>
      tester.widget(find.byType(DiarySegmentedProgressBar));

  testWidgets('fills up from zero to the eaten amount', (tester) async {
    await pumpBar(tester, current: 50);
    expect(bar(tester).progress, 0);

    await tester.pump(const Duration(milliseconds: 300));
    expect(bar(tester).progress, inExclusiveRange(0, 0.5));

    await tester.pumpAndSettle();
    expect(bar(tester).progress, 0.5);
    expect(bar(tester).overflow, 0);
  });

  testWidgets('stripes the overage once the filling passes the target', (
    tester,
  ) async {
    await pumpBar(tester, current: 150);

    await tester.pump(const Duration(milliseconds: 100));
    expect(bar(tester).overflow, 0);

    await tester.pumpAndSettle();
    expect(bar(tester).progress, 1.5);
    expect(bar(tester).overflow, closeTo(50 / 150, 0.0001));
  });

  testWidgets('animates from the old to the new amount', (tester) async {
    await pumpBar(tester, current: 20);
    await tester.pumpAndSettle();

    await pumpBar(tester, current: 80);
    await tester.pump(const Duration(milliseconds: 300));
    expect(bar(tester).progress, inExclusiveRange(0.2, 0.8));

    await tester.pumpAndSettle();
    expect(bar(tester).progress, 0.8);
  });

  testWidgets('animates down when the eaten amount shrinks', (tester) async {
    await pumpBar(tester, current: 150);
    await tester.pumpAndSettle();

    await pumpBar(tester, current: 30);
    await tester.pump(const Duration(milliseconds: 300));
    expect(bar(tester).progress, inExclusiveRange(0.3, 1.5));

    await tester.pumpAndSettle();
    expect(bar(tester).progress, 0.3);
    expect(bar(tester).overflow, 0);
  });
}
