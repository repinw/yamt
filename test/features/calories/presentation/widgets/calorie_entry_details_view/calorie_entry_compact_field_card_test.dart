import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_compact_field_card.dart';

void main() {
  testWidgets('renders uppercase label and child content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalorieEntryCompactFieldCard(
            label: 'Meal',
            child: Text('Breakfast'),
          ),
        ),
      ),
    );

    expect(find.text('MEAL'), findsOneWidget);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.byType(DecoratedBox), findsOneWidget);
  });
}
