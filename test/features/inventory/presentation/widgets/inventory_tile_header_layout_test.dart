import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/presentation/constants/'
    'inventory_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_tile_header_layout.dart';

void main() {
  testWidgets(
    'keeps long titles to two lines and uses compact progress height',
    (
      tester,
    ) async {
      const title = 'A very long inventory item name that needs room to wrap';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 260,
                child: InventoryTileHeaderLayout(
                  leading: SizedBox.square(dimension: 44),
                  title: title,
                  progressRatio: 0.5,
                  progressLabel: '250g / 500g',
                  segmentedByUnits: false,
                  totalUnits: 1,
                  remainingUnits: 0.5,
                  isExpanded: false,
                  showExpandIndicator: false,
                  action: SizedBox(width: 64, height: 40),
                ),
              ),
            ),
          ),
        ),
      );

      final titleText = tester.widget<Text>(find.text(title));
      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      expect(titleText.maxLines, 2);
      expect(progress.minHeight, AppInventoryClosedTile.progressHeight);
    },
  );
}
