import 'dart:developer' show log;

import 'package:mime/mime.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/product_search_hub/data/'
    'food_estimate_repository.dart';
import 'package:yamt/features/product_search_hub/data/'
    'product_photo_repository.dart';
import 'package:yamt/features/product_search_hub/domain/food_estimate.dart';
import 'package:yamt/features/product_search_hub/domain/product_photo.dart';

part 'food_estimate_controller.g.dart';

/// Most photos one estimate sends to the AI. A second photo helps when it
/// shows something new, such as the package next to the plate; more cost
/// tokens without a better estimate.
const foodEstimateMaxPhotos = 2;

/// Input and analysis state of the AI food estimate page.
class FoodEstimateState {
  /// Creates the state.
  const new({
    this.photos = const <FoodEstimatePhoto>[],
    this.estimate = const AsyncData<FoodEstimate?>(null),
    this.isLoadingPhotos = false,
    this.keptAddresses = const <String>[],
  });

  /// Photos in the order the user added them.
  final List<FoodEstimatePhoto> photos;

  /// The latest estimate; loading while the AI works.
  final AsyncValue<FoodEstimate?> estimate;

  /// Whether stored photos are still being read.
  final bool isLoadingPhotos;

  /// Addresses of stored photos that could not be read, for example
  /// offline. The AI does not see them, but the food keeps them (#763).
  final List<String> keptAddresses;

  /// Whether another photo fits.
  // Stored photos come first, so none is added while they load.
  bool get canAddPhoto =>
      !isLoadingPhotos &&
      photos.length + keptAddresses.length < foodEstimateMaxPhotos;

  /// Copies the state.
  FoodEstimateState copyWith({
    List<FoodEstimatePhoto>? photos,
    AsyncValue<FoodEstimate?>? estimate,
    bool? isLoadingPhotos,
    List<String>? keptAddresses,
  }) {
    return FoodEstimateState(
      photos: photos ?? this.photos,
      estimate: estimate ?? this.estimate,
      isLoadingPhotos: isLoadingPhotos ?? this.isLoadingPhotos,
      keptAddresses: keptAddresses ?? this.keptAddresses,
    );
  }
}

/// Collects photos and runs the AI food estimate.
@riverpod
class FoodEstimateController extends _$FoodEstimateController {
  @override
  FoodEstimateState build() => const FoodEstimateState();

  /// Adds a camera photo or gallery photos after the existing ones.
  Future<void> addPhotos({required bool fromCamera}) async {
    if (!state.canAddPhoto) return;
    final photos = await ref
        .read(foodEstimateRepositoryProvider)
        .loadPhotos(fromCamera: fromCamera);
    if (!ref.mounted || photos.isEmpty) return;
    state = state.copyWith(
      photos: [...state.photos, ...photos].take(foodEstimateMaxPhotos).toList(),
    );
  }

  /// Starts from the stored photos at [addresses], which keep their
  /// addresses, so they are not stored twice (#763). A photo that cannot be
  /// read keeps only its address; photos the user added meanwhile come
  /// after them. Analyzing waits until they are read.
  Future<void> loadStoredPhotos(List<String> addresses) async {
    final repository = ref.read(productPhotoRepositoryProvider);
    state = state.copyWith(isLoadingPhotos: true);
    final stored = addresses.take(foodEstimateMaxPhotos).toList();
    final read = await Future.wait([
      for (final address in stored) _readStored(repository, address),
    ]);
    if (!ref.mounted) return;
    final kept = [
      for (final (i, photo) in read.indexed)
        if (photo == null) stored[i],
    ];
    state = state.copyWith(
      photos: [
        ...read.nonNulls,
        ...state.photos,
      ].take(foodEstimateMaxPhotos - kept.length).toList(),
      isLoadingPhotos: false,
      keptAddresses: kept,
    );
  }

  static Future<FoodEstimatePhoto?> _readStored(
    ProductPhotoRepository repository,
    String address,
  ) async {
    try {
      final bytes = await repository.readPrivatePhoto(address);
      final mimeType = lookupMimeType(address, headerBytes: bytes);
      return (
        mimeType: mimeType ?? 'image/jpeg',
        bytes: bytes,
        address: address,
      );
    } on Object catch (error, stackTrace) {
      log(
        'Reading a stored food photo failed.',
        name: 'FoodEstimateController',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Starts storing every photo as a private food photo of the user and
  /// returns the running uploads in the photos' order, then the kept
  /// addresses. Their addresses are
  /// known before the uploads end, so the food can be saved right away
  /// (#845, #763). Throws when signed out.
  Future<List<ProductPhotoUpload>> savePhotos() async {
    final repository = ref.read(productPhotoRepositoryProvider);
    return await Future.wait([
      for (final photo in state.photos)
        if (photo.address case final address?)
          Future.value(
            ProductPhotoUpload(frontAddress: address, done: Future.value()),
          )
        else
          repository.savePrivateFrontPhoto(
            // The path is read only to scan a barcode, which a food photo is
            // never scanned for.
            ProductPhoto(
              path: '',
              bytes: photo.bytes,
              mimeType: photo.mimeType,
            ),
          ),
      for (final address in state.keptAddresses)
        Future.value(
          ProductPhotoUpload(frontAddress: address, done: Future.value()),
        ),
    ]);
  }

  /// Removes the photo at [index].
  void removePhoto(int index) {
    state = state.copyWith(
      photos: [
        for (final (i, photo) in state.photos.indexed)
          if (i != index) photo,
      ],
    );
  }

  /// Estimates the food from the photos and [description].
  ///
  /// Returns the estimate, or null when it failed; the error is then in
  /// [FoodEstimateState.estimate].
  Future<FoodEstimate?> analyze(String description) async {
    if (state.estimate.isLoading) return null;
    state = state.copyWith(estimate: const AsyncLoading<FoodEstimate?>());
    final result = await AsyncValue.guard<FoodEstimate?>(
      () => ref
          .read(foodEstimateRepositoryProvider)
          .loadEstimate(description: description, photos: state.photos),
    );
    if (!ref.mounted) return null;
    state = state.copyWith(estimate: result);
    return result.value;
  }
}
