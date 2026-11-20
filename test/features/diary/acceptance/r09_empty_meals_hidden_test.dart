import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

import '../../home/acceptance/acceptance_harness.dart';

void main() {
  testWidgets('R9: meal times without entries show no header', (tester) async {
    await pumpHomeShell(
      tester,
      calorieEntries: [
        CalorieEntry.placeholder(
          id: 'lunch',
          name: 'Nudeln',
          mealType: MealType.lunch,
          totalKcal: 700,
          loggedAt: DateTime(2026, 11, 19, 12),
        ),
        CalorieEntry.placeholder(
          id: 'dinner',
          name: 'Suppe',
          mealType: MealType.dinner,
          totalKcal: 400,
          loggedAt: DateTime(2026, 11, 19, 19),
        ),
      ],
    );

    expect(find.text('Mittagessen'), findsOneWidget);
    expect(find.text('Abendessen'), findsOneWidget);
    expect(find.text('Frühstück'), findsNothing);
    expect(find.text('Snack'), findsNothing);
    expect(find.text('Snacks'), findsNothing);
  });
}
