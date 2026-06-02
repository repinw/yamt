import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_repository.dart';

void main() {
  test('generateAiRecipe returns null when template client throws', () async {
    final repository = FirebaseAiChefRepository(
      templateModelClient: ({required templateId, required inputs}) async {
        throw Exception('template not found');
      },
    );

    final result = await repository.generateAiRecipe(
      languageCode: 'en',
      seed: 'pasta',
      inventoryIngredients: const <String>['Tomato'],
    );

    expect(result, isNull);
  });
}
