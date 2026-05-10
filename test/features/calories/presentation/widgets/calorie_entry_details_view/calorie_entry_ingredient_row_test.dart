import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_ingredient_row.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';

void main() {
  testWidgets('renders name brand amount and marker color', (tester) async {
    const accentColor = Color(0xFF00695C);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalorieEntryIngredientRow(
            component: CalorieEntryBundleComponent(
              name: 'Beans',
              amountLabel: '150 g',
              brand: 'Acme',
              totalKcal: 120,
              totalProtein: 8,
              totalCarbs: 18,
              totalFat: 1,
            ),
            index: 0,
            accentColor: accentColor,
          ),
        ),
      ),
    );

    final marker = tester.widget<Icon>(find.byIcon(Icons.circle));

    expect(
      find.byKey(CalorieEntryDetailKeys.ingredientNameCell(0)),
      findsOneWidget,
    );
    expect(
      find.byKey(CalorieEntryDetailKeys.ingredientAmountCell(0)),
      findsOneWidget,
    );
    expect(find.text('Beans'), findsOneWidget);
    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('150 g'), findsOneWidget);
    expect(marker.color, accentColor);
  });

  testWidgets('omits blank brand', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalorieEntryIngredientRow(
            component: CalorieEntryBundleComponent(
              name: 'Beans',
              amountLabel: '150 g',
              brand: ' ',
              totalKcal: 120,
              totalProtein: 8,
              totalCarbs: 18,
              totalFat: 1,
            ),
            index: 0,
            accentColor: Colors.green,
          ),
        ),
      ),
    );

    expect(find.text('Beans'), findsOneWidget);
    expect(find.text('150 g'), findsOneWidget);
    expect(find.text(' '), findsNothing);
  });
}
