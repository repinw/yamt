import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_thumbnail.dart';

void main() {
  testWidgets('renders fallback initial without stored image or image url', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalorieEntryThumbnail(
            entry: _entry(name: 'skyr', imageUrl: ' '),
            storedImageBytes: null,
          ),
        ),
      ),
    );

    expect(find.text('S'), findsOneWidget);
  });
}

CalorieEntry _entry({required String name, String? imageUrl}) {
  final loggedAt = DateTime(2026, 2, 25, 8);
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: name,
    mealType: MealType.breakfast,
    consumedAmount: 200,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    imageUrl: imageUrl,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}
