import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/'
    'calorie_nutrition_ocr_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_lookup_repository.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/provider/calorie_barcode_flow_controller.dart';
import '../support/fake_calories_repositories.dart';

void main() {
  CalorieProductProfile product({
    required String barcode,
    required CalorieProductSource source,
  }) {
    final now = DateTime(2026, 2, 25, 10);
    return CalorieProductProfile(
      barcode: barcode,
      name: 'Milk',
      brand: 'Acme',
      per100Kcal: 64,
      per100Protein: 3.2,
      per100Carbs: 4.8,
      per100Fat: 3.5,
      source: source,
      offProductId: 'off-1',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('resolveBarcode updates state with lookup outcome', () async {
    final lookupRepository = FakeCalorieProductLookupRepository(
      onLookupByBarcode: (barcode) async {
        return CalorieLookupOutcome.foundSingle(
          product(
            barcode: barcode,
            source: CalorieProductSource.globalCatalog,
          ),
        );
      },
    );
    final ocrRepository = FakeCalorieNutritionOcrRepository(
      onScanNutritionLabel: (barcode) async {
        return const CalorieNutritionOcrResult.failed(errorCode: 'x');
      },
    );

    final container = ProviderContainer(
      overrides: [
        calorieProductLookupRepositoryProvider.overrideWithValue(
          lookupRepository,
        ),
        calorieNutritionOcrRepositoryProvider.overrideWithValue(ocrRepository),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(calorieBarcodeFlowControllerProvider.notifier);
    final outcome = await notifier.resolveBarcode('4006381333931');
    final state = container.read(calorieBarcodeFlowControllerProvider);

    expect(outcome.status, CalorieLookupStatus.foundSingle);
    expect(state.asData?.value?.status, CalorieLookupStatus.foundSingle);
  });

  test('scanNutritionLabel returns success and failure', () async {
    final lookupRepository = FakeCalorieProductLookupRepository(
      onLookupByBarcode: (barcode) async {
        return const CalorieLookupOutcome.notFound();
      },
    );
    final now = DateTime(2026, 2, 25, 10);
    final successfulOcr = FakeCalorieNutritionOcrRepository(
      onScanNutritionLabel: (barcode) async {
        return CalorieNutritionOcrResult.succeeded(
          profile: CalorieProductProfile(
            barcode: barcode,
            name: 'Yogurt',
            per100Kcal: 80,
            per100Protein: 5,
            per100Carbs: 7,
            per100Fat: 3,
            source: CalorieProductSource.ocr,
            createdAt: now,
            updatedAt: now,
          ),
        );
      },
    );

    final successContainer = ProviderContainer(
      overrides: [
        calorieProductLookupRepositoryProvider.overrideWithValue(
          lookupRepository,
        ),
        calorieNutritionOcrRepositoryProvider.overrideWithValue(successfulOcr),
      ],
    );
    addTearDown(successContainer.dispose);
    final successResult = await successContainer
        .read(calorieBarcodeFlowControllerProvider.notifier)
        .scanNutritionLabel(barcode: '12345678');
    expect(successResult.status, CalorieNutritionOcrStatus.succeeded);

    final failingOcr = FakeCalorieNutritionOcrRepository(
      onScanNutritionLabel: (barcode) async {
        return const CalorieNutritionOcrResult.failed(errorCode: 'ocr_failed');
      },
    );
    final failureContainer = ProviderContainer(
      overrides: [
        calorieProductLookupRepositoryProvider.overrideWithValue(
          lookupRepository,
        ),
        calorieNutritionOcrRepositoryProvider.overrideWithValue(failingOcr),
      ],
    );
    addTearDown(failureContainer.dispose);
    final failedResult = await failureContainer
        .read(calorieBarcodeFlowControllerProvider.notifier)
        .scanNutritionLabel(barcode: '12345678');
    expect(failedResult.status, CalorieNutritionOcrStatus.failed);
    expect(failedResult.errorCode, 'ocr_failed');
  });
}
