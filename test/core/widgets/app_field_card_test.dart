import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_field_card.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

void main() {
  Widget buildCard(Widget card) {
    return MaterialApp(home: Scaffold(body: card));
  }

  testWidgets('without onTap renders content without an ink well', (
    tester,
  ) async {
    await tester.pumpWidget(buildCard(const AppFieldCard(child: Text('a'))));

    expect(find.text('a'), findsOneWidget);
    expect(find.byType(AppInkWell), findsNothing);
  });

  testWidgets('with onTap calls it when the tap target is tapped', (
    tester,
  ) async {
    const tapKey = Key('field_card_tap');
    var taps = 0;
    await tester.pumpWidget(
      buildCard(
        AppFieldCard(
          tapTargetKey: tapKey,
          onTap: () => taps++,
          child: const Text('b'),
        ),
      ),
    );

    await tester.tap(find.byKey(tapKey));

    expect(taps, 1);
  });
}
