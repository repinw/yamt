import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
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

  testWidgets('renders memory image when stored bytes exist', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalorieEntryThumbnail(
            entry: _entry(name: 'Skyr'),
            storedImageBytes: _transparentPngBytes,
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<MemoryImage>());
  });

  testWidgets('renders cached network image when image url exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalorieEntryThumbnail(
            entry: _entry(
              name: 'Skyr',
              imageUrl: 'https://images.example.com/skyr.jpg',
            ),
            storedImageBytes: null,
          ),
        ),
      ),
    );

    expect(find.byType(AppCachedNetworkImage), findsOneWidget);
  });
}

final _transparentPngBytes = Uint8List.fromList(const <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

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
