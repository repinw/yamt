import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/prepared_meal_cover.dart';

const _collageKey = Key('prepared_meal_cover_collage');

Future<void> _pump(WidgetTester tester, PreparedMealCover cover) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: cover)),
    ),
  );
}

void main() {
  testWidgets('shows the foods side by side without an own image', (
    tester,
  ) async {
    await _pump(
      tester,
      const PreparedMealCover(
        label: 'Milk + Oats',
        imageBytes: null,
        componentImageUrls: [
          'https://example.com/milk.png',
          null,
          'https://example.com/oats.png',
        ],
      ),
    );

    expect(find.byKey(_collageKey), findsOneWidget);
    expect(find.byType(AppCachedNetworkImage), findsNWidgets(2));
  });

  testWidgets('puts three or four foods in a grid', (tester) async {
    await _pump(
      tester,
      const PreparedMealCover(
        label: 'Bowl',
        imageBytes: null,
        componentImageUrls: [
          'https://example.com/a.png',
          'https://example.com/b.png',
          'https://example.com/c.png',
          'https://example.com/d.png',
          'https://example.com/e.png',
        ],
      ),
    );

    expect(find.byType(AppCachedNetworkImage), findsNWidgets(4));
    expect(find.byType(Row), findsNWidgets(2));
  });

  testWidgets('an own image wins over the foods', (tester) async {
    await _pump(
      tester,
      const PreparedMealCover(
        label: 'Milk + Oats',
        imageBytes: null,
        imageUrl: 'https://example.com/meal.png',
        componentImageUrls: ['https://example.com/milk.png'],
      ),
    );

    expect(find.byKey(_collageKey), findsNothing);
    expect(find.byType(AppCachedNetworkImage), findsOneWidget);
  });

  testWidgets('shows the initial without any image', (tester) async {
    await _pump(
      tester,
      const PreparedMealCover(label: 'soup', imageBytes: null),
    );

    expect(find.text('S'), findsOneWidget);
  });
}
