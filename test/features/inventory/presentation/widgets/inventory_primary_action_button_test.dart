import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_primary_action_button.dart';

void main() {
  testWidgets('uses configured border radius', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InventoryPrimaryActionButton(
            tooltip: 'Eat',
            onPressed: () {},
            showText: true,
            label: 'Eat',
            width: 96,
            height: 48,
            enabledBackgroundColor: Colors.green,
            disabledBackgroundColor: Colors.grey,
            enabledBorderColor: Colors.green,
            disabledBorderColor: Colors.grey,
            enabledForegroundColor: Colors.black,
            disabledForegroundColor: Colors.white,
            useGradientWhenShowText: false,
            borderRadius: 12,
          ),
        ),
      ),
    );

    final decoratedBox = tester.widget<DecoratedBox>(
      find.byType(DecoratedBox),
    );
    final decoration = decoratedBox.decoration as BoxDecoration;

    expect(decoration.borderRadius, BorderRadius.circular(12));
  });
}
