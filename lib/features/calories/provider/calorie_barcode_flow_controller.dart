import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/'
    'calorie_nutrition_ocr_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_lookup_repository.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

part 'calorie_barcode_flow_controller.g.dart';

/// Defines calorie barcode flow controller.
@riverpod
class CalorieBarcodeFlowController extends _$CalorieBarcodeFlowController {
  @override
  FutureOr<CalorieLookupOutcome?> build() {
    ref.watch(calorieProductLookupRepositoryProvider);
    ref.watch(calorieNutritionOcrRepositoryProvider);
    return null;
  }

  /// Resolve barcode.
  Future<CalorieLookupOutcome> resolveBarcode(String rawBarcode) async {
    final lookupRepository = ref.read(calorieProductLookupRepositoryProvider);
    state = const AsyncLoading();
    final outcome = await lookupRepository.lookupByBarcode(rawBarcode);
    if (ref.mounted) {
      state = AsyncData(outcome);
    }
    return outcome;
  }

  /// Persist selected candidate.
  Future<bool> persistSelectedCandidate(CalorieProductProfile profile) {
    final lookupRepository = ref.read(calorieProductLookupRepositoryProvider);
    return lookupRepository.persistGlobalProduct(profile);
  }

  /// Scan nutrition label.
  Future<CalorieNutritionOcrResult> scanNutritionLabel({
    required String barcode,
  }) {
    final ocrRepository = ref.read(calorieNutritionOcrRepositoryProvider);
    return ocrRepository.scanNutritionLabel(barcode: barcode);
  }
}
