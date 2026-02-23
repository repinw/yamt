import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/remaining_progress_bar.dart';

void main() {
  Widget buildWidget({
    required bool segmentedByUnits,
    required int totalUnits,
    required int remainingUnits,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: RemainingProgressBar(
          ratio: 0.5,
          stockLabel: '1/2',
          segmentedByUnits: segmentedByUnits,
          totalUnits: totalUnits,
          remainingUnits: remainingUnits,
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
}
