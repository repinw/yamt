import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/off_product_search_result.dart';
import 'package:yamt/features/inventory/data/off_product_search_result_quality.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

const _completeNutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
  per100Kcal: 64,
  per100Fat: 3.5,
  per100SaturatedFat: 2.2,
  per100Carbs: 4.8,
  per100Sugar: 4.8,
  per100Protein: 3.4,
  per100Salt: 0.12,
);

const _verifiedNutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 64,
  per100Fat: 3.5,
  per100SaturatedFat: 2.2,
  per100Carbs: 4.8,
  per100Sugar: 4.8,
  per100Protein: 3.4,
  per100Salt: 0.12,
);

const _incompleteNutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
  per100Kcal: 64,
  per100Fat: 3.5,
  per100Carbs: 4.8,
  per100Protein: 3.4,
);

void main() {
  test('gradeOffProductNutrition separates completeness from verification', () {
    expect(
      gradeOffProductNutrition(null),
      OffProductNutritionGrade.missing,
    );
    expect(
      gradeOffProductNutrition(
        const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
          per100Protein: 3.4,
        ),
      ),
      OffProductNutritionGrade.missingCalories,
    );
    expect(
      gradeOffProductNutrition(_incompleteNutrition),
      OffProductNutritionGrade.incomplete,
    );
    expect(
      gradeOffProductNutrition(_completeNutrition),
      OffProductNutritionGrade.complete,
    );
    expect(
      gradeOffProductNutrition(_verifiedNutrition),
      OffProductNutritionGrade.verified,
    );
  });

  test(
    'collapseDominatedOffProductSearchResults keeps best safe duplicate',
    () {
      final results = collapseDominatedOffProductSearchResults(
        const <OffProductSearchResult>[
          OffProductSearchResult(
            code: '4006381333931',
            name: 'Milk',
            brand: 'Acme',
            packageWeight: '1 l',
            score: 100,
            nutrition: _incompleteNutrition,
          ),
          OffProductSearchResult(
            code: '4006381333931',
            name: 'Milk',
            brand: 'Acme',
            packageWeight: '1000 ml',
            score: 90,
            nutrition: _completeNutrition,
          ),
        ],
      );

      expect(results, hasLength(1));
      expect(results.single.nutrition, _completeNutrition);
    },
  );

  test(
    'collapseDominatedOffProductSearchResults prefers same-grade extra fields',
    () {
      final results = collapseDominatedOffProductSearchResults(
        const <OffProductSearchResult>[
          OffProductSearchResult(
            code: '4006381333931',
            name: 'Milk',
            brand: 'Acme',
            packageWeight: '1 l',
            score: 100,
            nutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
              per100Kcal: 64,
            ),
          ),
          OffProductSearchResult(
            code: '4006381333931',
            name: 'Milk',
            brand: 'Acme',
            packageWeight: '1000 ml',
            score: 90,
            nutrition: _incompleteNutrition,
          ),
        ],
      );

      expect(results, hasLength(1));
      expect(results.single.nutrition, _incompleteNutrition);
    },
  );

  test(
    'collapseDominatedOffProductSearchResults keeps nutrition conflicts',
    () {
      final results = collapseDominatedOffProductSearchResults(
        const <OffProductSearchResult>[
          OffProductSearchResult(
            code: '4006381333931',
            name: 'Milk',
            brand: 'Acme',
            packageWeight: '1 l',
            score: 100,
            nutrition: _completeNutrition,
          ),
          OffProductSearchResult(
            code: '4006381333931',
            name: 'Milk',
            brand: 'Acme',
            packageWeight: '1 l',
            score: 90,
            nutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 120,
              per100Fat: 3.5,
              per100SaturatedFat: 2.2,
              per100Carbs: 4.8,
              per100Sugar: 4.8,
              per100Protein: 3.4,
              per100Salt: 0.12,
            ),
          ),
        ],
      );

      expect(results, hasLength(2));
    },
  );

  test('collapseDominatedOffProductSearchResults keeps package conflicts', () {
    final results = collapseDominatedOffProductSearchResults(
      const <OffProductSearchResult>[
        OffProductSearchResult(
          code: '4006381333931',
          name: 'Milk',
          brand: 'Acme',
          packageWeight: '500 ml',
          score: 100,
          nutrition: _incompleteNutrition,
        ),
        OffProductSearchResult(
          code: '4006381333931',
          name: 'Milk',
          brand: 'Acme',
          packageWeight: '1 l',
          score: 90,
          nutrition: _completeNutrition,
        ),
      ],
    );

    expect(results, hasLength(2));
  });
}
