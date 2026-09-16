import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_meal_thumb.dart';

void main() {
  const entry = DiaryMealEntry(
    id: 'food_1',
    mealType: MealType.breakfast,
    name: 'Haferflocken',
    totalKcal: 200,
    totalProtein: 10,
    totalCarbs: 30,
    totalFat: 5,
  );

  Widget buildTestWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: MealThumb(entry: entry),
          ),
        ),
      ),
    );
  }

  testWidgets('MealThumb renders regular dimensions and initial fallback', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    final sizedBox = tester.widget<SizedBox>(
      find.descendant(
        of: find.byType(MealThumb),
        matching: find.byType(SizedBox),
      ),
    );
    expect(sizedBox.width, 54);
    expect(sizedBox.height, 54);

    final clipRRect = tester.widget<ClipRRect>(
      find.descendant(
        of: find.byType(MealThumb),
        matching: find.byType(ClipRRect),
      ),
    );
    expect(clipRRect.borderRadius, BorderRadius.circular(AppRadius.md));

    expect(find.text('H'), findsOneWidget);
  });
}
