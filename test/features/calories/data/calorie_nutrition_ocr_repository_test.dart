import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_nutrition_ocr_repository.dart';

void main() {
  test('template config client always returns nutrition-template-id', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final client = container.read(calorieNutritionTemplateConfigClientProvider);
    final templateId = await client.loadTemplateId();

    expect(templateId, 'nutrition-template-id');
  });
}
