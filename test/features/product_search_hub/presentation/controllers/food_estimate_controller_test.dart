import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/product_search_hub/data/'
    'food_estimate_repository.dart';
import 'package:yamt/features/product_search_hub/data/'
    'product_photo_repository.dart';
import 'package:yamt/features/product_search_hub/domain/food_estimate.dart';
import 'package:yamt/features/product_search_hub/domain/product_photo.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_exceptions.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'food_estimate_controller.dart';

class _FakeFoodEstimateRepository implements FoodEstimateRepository {
  new(this._onLoad);

  final Future<FoodEstimate> Function() _onLoad;
  List<FoodEstimatePhoto> nextPhotos = const [];
  final List<bool> photoSources = <bool>[];
  List<FoodEstimatePhoto>? lastPhotos;

  @override
  Future<List<FoodEstimatePhoto>> loadPhotos({required bool fromCamera}) async {
    photoSources.add(fromCamera);
    return nextPhotos;
  }

  @override
  Future<FoodEstimate> loadEstimate({
    required String description,
    required List<FoodEstimatePhoto> photos,
  }) {
    lastPhotos = photos;
    return _onLoad();
  }
}

/// Stored food photos by address; a new photo gets the next address.
class _StoredPhotos implements ProductPhotoRepository {
  final stored = <String, Uint8List>{
    'gs://yamt/users/u1/food_photos/a.jpg': Uint8List.fromList([5]),
  };
  final saved = <int>[];

  @override
  Future<Uint8List> readPrivatePhoto(String address) async =>
      stored[address] ?? (throw StateError('missing $address'));

  @override
  Future<ProductPhotoUpload> savePrivateFrontPhoto(ProductPhoto front) async {
    saved.add(front.bytes.single);
    return ProductPhotoUpload(
      frontAddress: 'gs://yamt/new-${saved.length}.jpg',
      done: Future.value(),
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
    (mimeType: 'image/jpeg', bytes: Uint8List.fromList([byte]), address: null);

ProviderContainer _container(
  FoodEstimateRepository repository, {
  ProductPhotoRepository? photos,
}) {
  final container = ProviderContainer(
    overrides: [
      foodEstimateRepositoryProvider.overrideWithValue(repository),
      if (photos != null)
        productPhotoRepositoryProvider.overrideWithValue(photos),
    ],
  );
  addTearDown(container.dispose);
  container.listen(foodEstimateControllerProvider, (_, _) {});
  return container;
}

void main() {
  test('adds and removes photos, two at most', () async {
    final repository = _FakeFoodEstimateRepository(() async => _estimate)
      ..nextPhotos = [_photo(1), _photo(2), _photo(9)];
    final container = _container(repository);
    final notifier = container.read(foodEstimateControllerProvider.notifier);
    List<int> bytes() => [
      for (final photo in container.read(foodEstimateControllerProvider).photos)
        photo.bytes.single,
    ];

    await notifier.addPhotos(fromCamera: false);
    expect(bytes(), [1, 2]);

    repository.nextPhotos = [_photo(3)];
    await notifier.addPhotos(fromCamera: true);
    expect(repository.photoSources, [false]);

    notifier.removePhoto(1);
    await notifier.addPhotos(fromCamera: true);

    expect(repository.photoSources, [false, true]);
    expect(bytes(), [1, 3]);
  });

  test('analyze sends the photos and goes through loading', () async {
    final repository = _FakeFoodEstimateRepository(() async => _estimate)
      ..nextPhotos = [_photo(7)];
    final container = _container(repository);
    final states = <AsyncValue<FoodEstimate?>>[];
    container.listen(
      foodEstimateControllerProvider.select((state) => state.estimate),
      (_, next) => states.add(next),
    );
    final notifier = container.read(foodEstimateControllerProvider.notifier);
    await notifier.addPhotos(fromCamera: false);

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

  test('a stored AI food starts from its photos and stores only new ones '
      '(#763)', () async {
    final repository = _FakeFoodEstimateRepository(() async => _estimate)
      ..nextPhotos = [_photo(7)];
    final photos = _StoredPhotos();
    final container = _container(repository, photos: photos);
    final notifier = container.read(foodEstimateControllerProvider.notifier);

    await notifier.loadStoredPhotos(['gs://yamt/users/u1/food_photos/a.jpg']);
    final loaded = container.read(foodEstimateControllerProvider).photos;
    expect([for (final photo in loaded) photo.bytes.single], [5]);

    await notifier.addPhotos(fromCamera: true);
    final uploads = await notifier.savePhotos();

    expect(
      [for (final upload in uploads) upload.frontAddress],
      ['gs://yamt/users/u1/food_photos/a.jpg', 'gs://yamt/new-1.jpg'],
    );
    expect(photos.saved, [7]);
  });

  test('a stored photo that cannot be read keeps its address and its place '
      '(#763)', () async {
    final repository = _FakeFoodEstimateRepository(() async => _estimate)
      ..nextPhotos = [_photo(7)];
    final photos = _StoredPhotos();
    final container = _container(repository, photos: photos);
    final notifier = container.read(foodEstimateControllerProvider.notifier);

    await notifier.loadStoredPhotos([
      'gs://yamt/users/u1/food_photos/a.jpg',
      'gs://yamt/users/u1/food_photos/offline.jpg',
    ]);
    final state = container.read(foodEstimateControllerProvider);
    expect([for (final photo in state.photos) photo.bytes.single], [5]);
    // The unread photo still takes a place.
    expect(state.canAddPhoto, isFalse);

    await notifier.addPhotos(fromCamera: true);
    final uploads = await notifier.savePhotos();

    expect(
      [for (final upload in uploads) upload.frontAddress],
      [
        'gs://yamt/users/u1/food_photos/a.jpg',
        'gs://yamt/users/u1/food_photos/offline.jpg',
      ],
    );
    expect(photos.saved, isEmpty);
  });

  test('photos the user added while stored ones load come after them '
      '(#763)', () async {
    final repository = _FakeFoodEstimateRepository(() async => _estimate)
      ..nextPhotos = [_photo(7)];
    final container = _container(repository, photos: _StoredPhotos());
    final notifier = container.read(foodEstimateControllerProvider.notifier);

    await notifier.addPhotos(fromCamera: true);
    final loading = notifier.loadStoredPhotos([
      'gs://yamt/users/u1/food_photos/a.jpg',
    ]);
    // No photo is added while stored ones load.
    expect(container.read(foodEstimateControllerProvider).canAddPhoto, isFalse);
    await loading;

    final shown = container.read(foodEstimateControllerProvider).photos;
    expect([for (final photo in shown) photo.bytes.single], [5, 7]);
    expect(
      container.read(foodEstimateControllerProvider).isLoadingPhotos,
      isFalse,
    );
  });
}
