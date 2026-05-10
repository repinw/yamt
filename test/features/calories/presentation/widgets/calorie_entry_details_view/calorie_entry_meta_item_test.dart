import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_meta_item.dart';

void main() {
  testWidgets('renders icon and keyed label', (tester) async {
    const valueKey = Key('meta-value');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalorieEntryMetaItem(
            icon: Icons.scale_outlined,
            label: '200 g',
            valueKey: valueKey,
          ),
        ),
      ),
    );

    final label = tester.widget<Text>(find.byKey(valueKey));

    expect(find.byIcon(Icons.scale_outlined), findsOneWidget);
    expect(label.data, '200 g');
    expect(label.maxLines, 1);
    expect(label.overflow, TextOverflow.ellipsis);
  });
}
