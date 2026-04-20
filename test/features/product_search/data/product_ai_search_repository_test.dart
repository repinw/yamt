import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/product_search/data/'
    'product_ai_search_repository.dart';

void main() {
  test('generateFoodFromText parses valid AI response', () async {
    String? lastTemplateId;
    Map<String, Object?>? lastInputs;
    final repository = FirebaseProductAiSearchRepository(
      generateContent: ({required templateId, required inputs}) async {
        lastTemplateId = templateId;
        lastInputs = inputs;
        return '''
{
  "name": "Doener Haehnchen",
  "ingredients": [
    {
      "label": "Fladenbrot",
      "amount_text": "100 g",
      "amount_grams": 100,
      "kcal": 280,
      "protein": 9,
      "carbs": 54,
      "fat": 3
    },
    {
      "label": "Haehnchen",
      "amount_text": "150 g",
      "amount_grams": 150,
      "kcal": 300,
      "protein": 33,
      "carbs": 0,
      "fat": 18
    }
  ],
  "total": {
    "weight_grams": 380,
    "kcal_min": 800,
    "kcal_max": 950,
    "kcal_default": 880
  },
  "nutrition_per_portion": {
    "kcal": 880,
    "protein": 42,
    "carbs": 68,
    "fat": 38,
    "salt": 2.8
  }
}
''';
      },
    );

    final draft = await repository.generateFoodFromText(
      prompt: 'Doener Haehnchen',
    );

    expect(draft, isNotNull);
    expect(draft?.name, 'Doener Haehnchen');
    expect(draft?.ingredients.length, 2);
    expect(draft?.ingredients.first.kcalMin, 280);
    expect(draft?.ingredients.first.kcalMax, 280);
    expect(draft?.ingredients.first.protein, 9);
    expect(draft?.totalWeightGrams, 380);
    expect(draft?.defaultKcal, 880);
    expect(
      draft
          ?.per100NutritionForKcal(
            value: 880,
            qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
          )
          .per100Kcal,
      231.58,
    );
    expect(lastTemplateId, 'product-ai-search-template');
    expect(
      lastInputs,
      <String, Object?>{'prompt': 'Doener Haehnchen'},
    );
  });

  test(
    'generateFoodFromText returns null for invalid response payload',
    () async {
      final repository = FirebaseProductAiSearchRepository(
        generateContent: ({required templateId, required inputs}) async {
          return '{"name":"Doener"}';
        },
      );

      final draft = await repository.generateFoodFromText(prompt: 'Doener');

      expect(draft, isNull);
    },
  );

  test('generateFoodFromText accepts fenced json response', () async {
    final repository = FirebaseProductAiSearchRepository(
      generateContent: ({required templateId, required inputs}) async {
        return '''
```json
{
  "name": "Doener",
  "ingredients": [
    {
      "label": "Bread",
      "amount_text": "100 g",
      "amount_grams": 100,
      "kcal_min": 250,
      "kcal_max": 300
    }
  ],
  "total": {
    "weight_grams": 100,
    "kcal_min": 250,
    "kcal_max": 300
  },
  "nutrition_per_100": {
    "kcal": 275,
    "protein": 10,
    "carbs": 30,
    "fat": 8
  }
}
```
''';
      },
    );

    final draft = await repository.generateFoodFromText(prompt: 'Doener');

    expect(draft, isNotNull);
    expect(draft?.defaultKcal, 275);
  });

  test('generateFoodFromText accepts zero kcal ingredient rows', () async {
    final repository = FirebaseProductAiSearchRepository(
      generateContent: ({required templateId, required inputs}) async {
        return '''
{
  "name": "Pelmeni mit Schweinefleisch",
  "ingredients": [
    {
      "label": "Weizenmehl",
      "amount_text": "100 g",
      "amount_grams": 100,
      "kcal": 364,
      "protein": 10,
      "carbs": 76,
      "fat": 1
    },
    {
      "label": "Salz und Gewuerze",
      "amount_text": "5 g",
      "amount_grams": 5,
      "kcal": 0,
      "protein": 0,
      "carbs": 0,
      "fat": 0
    }
  ],
  "total": {
    "weight_grams": 250,
    "kcal_min": 580,
    "kcal_max": 720,
    "kcal_default": 643
  },
  "nutrition_per_portion": {
    "kcal": 643,
    "protein": 31.8,
    "carbs": 78.4,
    "fat": 21.1,
    "salt": 1.5
  }
}
''';
      },
    );

    final draft = await repository.generateFoodFromText(
      prompt: 'Pelmeni mit Schweinefleisch',
    );

    expect(draft, isNotNull);
    expect(draft?.ingredients.last.kcalMin, 0);
    expect(draft?.ingredients.last.kcalMax, 0);
  });

  test('generateFoodFromText skips empty normalized prompt', () async {
    var didCallGenerator = false;
    final repository = FirebaseProductAiSearchRepository(
      generateContent: ({required templateId, required inputs}) async {
        didCallGenerator = true;
        return null;
      },
    );

    final draft = await repository.generateFoodFromText(prompt: '   ');

    expect(draft, isNull);
    expect(didCallGenerator, isFalse);
  });

  test('generateFoodFromText falls back to per-100 nutrition block', () async {
    final repository = FirebaseProductAiSearchRepository(
      generateContent: ({required templateId, required inputs}) async {
        return '''
{
  "name": "Pelmeni",
  "ingredients": [
    {
      "label": "Teig",
      "amount_text": "200 g",
      "amount_grams": 200,
      "kcal": 420
    }
  ],
  "total": {
    "weight_grams": 400,
    "kcal_min": 700,
    "kcal_max": 900,
    "kcal_default": 820
  },
  "nutrition_per_portion": {
    "kcal": -1
  },
  "nutrition_per_100": {
    "kcal": 205,
    "protein": 10,
    "carbs": 18,
    "fat": 10
  }
}
''';
      },
    );

    final draft = await repository.generateFoodFromText(prompt: 'Pelmeni');

    expect(draft, isNotNull);
    expect(draft?.portionNutrition.kcal, 820);
    expect(draft?.portionNutrition.protein, 40);
  });
}
