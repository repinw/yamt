import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_action_picker_sheet.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('InventoryActionPickerOptionTile renders without subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        InventoryActionPickerOptionTile(
          icon: Icons.delete_outline_rounded,
          title: 'Discard',
          foregroundColor: Colors.red,
          backgroundColor: Colors.red.shade50,
          onPressed: () {},
        ),
      ),
    );

    expect(find.text('Discard'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(find.text('Throw it away'), findsNothing);
  });

  testWidgets('InventoryActionPickerOptionTile renders subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        InventoryActionPickerOptionTile(
          icon: Icons.restaurant_rounded,
          title: 'Eat now',
          subtitle: 'Log calories and reduce stock.',
          foregroundColor: Colors.green,
          backgroundColor: Colors.green.shade50,
          onPressed: () {},
        ),
      ),
    );

    expect(find.text('Eat now'), findsOneWidget);
    expect(find.text('Log calories and reduce stock.'), findsOneWidget);
  });

  testWidgets('InventoryActionPickerOptionTile invokes onPressed', (
    tester,
  ) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _wrap(
        InventoryActionPickerOptionTile(
          icon: Icons.close_rounded,
          title: 'Delete',
          foregroundColor: Colors.grey,
          backgroundColor: Colors.grey.shade200,
          onPressed: () => tapCount += 1,
        ),
      ),
    );

    await tester.tap(find.text('Delete'));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('InventoryActionPickerOptionTile applies colors', (
    tester,
  ) async {
    const foregroundColor = Colors.deepPurple;
    const backgroundColor = Color(0xFFEDE7F6);

    await tester.pumpWidget(
      _wrap(
        InventoryActionPickerOptionTile(
          icon: Icons.more_horiz_rounded,
          title: 'Other',
          subtitle: 'Choose another reason.',
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
          onPressed: () {},
        ),
      ),
    );

    final ink = tester.widget<Ink>(find.byType(Ink));
    final decoration = ink.decoration as BoxDecoration;
    expect(decoration.color, backgroundColor);

    final title = tester.widget<Text>(find.text('Other'));
    expect(title.style?.color, foregroundColor);

    final subtitle = tester.widget<Text>(find.text('Choose another reason.'));
    expect(subtitle.style?.color, foregroundColor.withValues(alpha: 0.78));

    final icon = tester.widget<Icon>(find.byIcon(Icons.more_horiz_rounded));
    expect(icon.color, foregroundColor);
  });
}
