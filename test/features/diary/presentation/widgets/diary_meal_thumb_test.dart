import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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
          body: Center(child: MealThumb(entry: entry)),
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
    expect(sizedBox.width, 44);
    expect(sizedBox.height, 44);

    final clipRRect = tester.widget<ClipRRect>(
      find.descendant(
        of: find.byType(MealThumb),
        matching: find.byType(ClipRRect),
      ),
    );
    expect(clipRRect.borderRadius, BorderRadius.circular(AppRadius.md));

    expect(find.text('H'), findsOneWidget);
  });

  testWidgets('MealThumb flies as a hero only with an image and when enabled', (
    tester,
  ) async {
    Widget thumb(DiaryMealEntry entry, {required bool heroEnabled}) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: MealThumb(entry: entry, heroEnabled: heroEnabled),
            ),
          ),
        ),
      );
    }

    const withImage = DiaryMealEntry(
      id: 'food_2',
      mealType: MealType.breakfast,
      name: 'Skyr',
      imageUrl: 'https://example.com/skyr.png',
      totalKcal: 100,
      totalProtein: 10,
      totalCarbs: 4,
      totalFat: 0,
    );

    await tester.pumpWidget(thumb(withImage, heroEnabled: true));
    expect(find.byType(Hero), findsOneWidget);

    await tester.pumpWidget(thumb(withImage, heroEnabled: false));
    expect(find.byType(Hero), findsNothing);

    await tester.pumpWidget(thumb(entry, heroEnabled: true));
    expect(find.byType(Hero), findsNothing);
  });
}
