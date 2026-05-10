import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'remaining_progress_bar.dart';

void main() {
  Widget buildWidget({
    required bool segmentedByUnits,
    required int totalUnits,
    required int remainingUnits,
    String stockLabel = '1/2',
    RemainingProgressBarLabelLayout labelLayout =
        RemainingProgressBarLabelLayout.belowBar,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: RemainingProgressBar(
          ratio: 0.5,
          stockLabel: stockLabel,
          segmentedByUnits: segmentedByUnits,
          totalUnits: totalUnits,
          remainingUnits: remainingUnits,
          labelLayout: labelLayout,
        ),
      ),
    );
  }

  testWidgets('renders one bar when segmentation is disabled', (tester) async {
    await tester.pumpWidget(
      buildWidget(segmentedByUnits: false, totalUnits: 2, remainingUnits: 1),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('renders one bar per unit when segmentation is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(segmentedByUnits: true, totalUnits: 2, remainingUnits: 1),
    );

    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
  });

  testWidgets('falls back to a single bar for large unit counts', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(segmentedByUnits: true, totalUnits: 20, remainingUnits: 10),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('highlights current amount before slash', (tester) async {
    await tester.pumpWidget(
      buildWidget(
        segmentedByUnits: false,
        totalUnits: 2,
        remainingUnits: 1,
        stockLabel: '315g / 500g',
        labelLayout: RemainingProgressBarLabelLayout.aboveBar,
      ),
    );

    final richText = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains('500g'),
      ),
    );
    final rootSpan = richText.text as TextSpan;
    final currentAmount = rootSpan.children!.first as TextSpan;
    final remainder = rootSpan.children![1] as TextSpan;

    expect(currentAmount.text?.trim(), '315g');
    expect(currentAmount.style?.fontWeight, FontWeight.w800);
    expect(currentAmount.style?.color, isNotNull);
    expect(remainder.text, '/ 500g');
  });

  testWidgets('shows labels above bar when configured', (tester) async {
    await tester.pumpWidget(
      buildWidget(
        segmentedByUnits: false,
        totalUnits: 2,
        remainingUnits: 1,
        stockLabel: '315g / 500g',
        labelLayout: RemainingProgressBarLabelLayout.aboveBar,
      ),
    );

    final percentageRect = tester.getRect(find.text('50%'));
    final progressRect = tester.getRect(find.byType(LinearProgressIndicator));

    expect(percentageRect.bottom, lessThan(progressRect.top));
  });

  testWidgets('uses rounded progress indicator border radius', (tester) async {
    await tester.pumpWidget(
      buildWidget(segmentedByUnits: false, totalUnits: 2, remainingUnits: 1),
    );

    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );

    expect(progress.borderRadius, BorderRadius.circular(999));
  });
}
