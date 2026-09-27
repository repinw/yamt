import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/product_search_hub/data/'
    'food_estimate_repository.dart';
import 'package:yamt/features/product_search_hub/domain/food_estimate.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_exceptions.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'food_estimate_controller.dart';

class _FakeFoodEstimateRepository implements FoodEstimateRepository {
  new(this._onLoad);

  final Future<FoodEstimate> Function() _onLoad;
  List<FoodEstimatePhoto>? lastPhotos;

  @override
  Future<FoodEstimate> loadEstimate({
    required String description,
    required List<FoodEstimatePhoto> photos,
  }) {
    lastPhotos = photos;
    return _onLoad();
  }
}

const _estimate = FoodEstimate(
  name: 'Apfel',
  portionGrams: 160,
  kcalLean: 80,
  kcalRich: 90,
  per100: GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
    per100Kcal: 52,
  ),
  ingredients: [],
);

FoodEstimatePhoto _photo(int byte) =>
    (mimeType: 'image/jpeg', bytes: Uint8List.fromList([byte]));

ProviderContainer _container(FoodEstimateRepository repository) {
  final container = ProviderContainer(
    overrides: [foodEstimateRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  container.listen(foodEstimateControllerProvider, (_, _) {});
  return container;
}

void main() {
  test('adds and removes photos', () {
    final container = _container(
      _FakeFoodEstimateRepository(() async => _estimate),
    );
    container.read(foodEstimateControllerProvider.notifier)
      ..addPhotos([_photo(1), _photo(2)])
      ..addPhotos([_photo(3)])
      ..removePhoto(1);

    expect(
      container
          .read(foodEstimateControllerProvider)
          .photos
          .map((photo) => photo.bytes.single),
      [1, 3],
    );
  });

  test('analyze sends the photos and goes through loading', () async {
    final repository = _FakeFoodEstimateRepository(() async => _estimate);
    final container = _container(repository);
    final states = <AsyncValue<FoodEstimate?>>[];
    container.listen(
      foodEstimateControllerProvider.select((state) => state.estimate),
      (_, next) => states.add(next),
    );
    final notifier = container.read(foodEstimateControllerProvider.notifier)
      ..addPhotos([_photo(7)]);

    final estimate = await notifier.analyze('Apfel');

    expect(estimate, _estimate);
    expect(repository.lastPhotos?.single.bytes.single, 7);
    expect(states.first, isA<AsyncLoading<FoodEstimate?>>());
    expect(states.last.value, _estimate);
  });

  test('analyze keeps the error for the page', () async {
    final container = _container(
      _FakeFoodEstimateRepository(
        () async => throw const FoodEstimateUnclearException(),
      ),
    );

    final estimate = await container
        .read(foodEstimateControllerProvider.notifier)
        .analyze('?');

    expect(estimate, isNull);
    expect(
      container.read(foodEstimateControllerProvider).estimate.error,
      isA<FoodEstimateUnclearException>(),
    );
  });
}
