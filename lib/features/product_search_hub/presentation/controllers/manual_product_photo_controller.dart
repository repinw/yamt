import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/product_nutrition/data/'
    'nutrition_label_ocr_repository.dart';
import 'package:yamt/features/product_nutrition/domain/'
    'nutrition_label_ocr_models.dart';
import 'package:yamt/features/product_search_hub/data/'
    'product_photo_repository.dart';
import 'package:yamt/features/product_search_hub/domain/product_photo.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_exceptions.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';

part 'manual_product_photo_controller.g.dart';

const _logName = 'ManualProductPhotoController';

/// How reading a package photo ended.
enum ManualProductPhotoOutcome {
  /// The photo was read and its values are filled in.
  read,

  /// The user closed the camera.
  canceled,

  /// This device cannot take photos.
  cameraUnsupported,

  /// The photo shows no food package.
  notProduct,

  /// The product name or the nutrition table is not readable; a new photo
  /// can fix it.
  retakePhoto,

  /// Firebase App Check blocked the AI request for a while.
  appCheckThrottled,

  /// The AI request failed.
  failed,
}

/// The two package photos of the product editor.
class ManualProductPhotoState {
  /// Creates the state.
  const new({
    this.front,
    this.nutritionTable,
    this.isReadingFront = false,
    this.isReadingNutritionTable = false,
    this.hasReadFront = false,
    this.hasReadNutritionTable = false,
    this.isSaving = false,
    this.frontDetails,
    this.nutritionValueCount = 0,
  });

  /// Photo of the package front.
  final ProductPhoto? front;

  /// Photo of the nutrition table.
  final ProductPhoto? nutritionTable;

  /// Whether the AI reads the front photo.
  final bool isReadingFront;

  /// Whether the AI reads the nutrition table photo.
  final bool isReadingNutritionTable;

  /// Whether the front photo filled in the product.
  final bool hasReadFront;

  /// Whether the nutrition table photo filled in the values.
  final bool hasReadNutritionTable;

  /// Whether the photos are being stored.
  final bool isSaving;

  /// What the AI read on the front photo.
  final ProductFrontDetails? frontDetails;

  /// Number of nutrition values read from the nutrition table photo.
  final int nutritionValueCount;

  /// Whether a photo is being read or stored.
  bool get isBusy => isReadingFront || isReadingNutritionTable || isSaving;

  /// Whether the user took a photo.
  bool get hasPhoto => front != null || nutritionTable != null;

  /// Copies the state.
  ManualProductPhotoState copyWith({
    ProductPhoto? front,
    ProductPhoto? nutritionTable,
    bool? isReadingFront,
    bool? isReadingNutritionTable,
    bool? hasReadFront,
    bool? hasReadNutritionTable,
    bool? isSaving,
    ProductFrontDetails? frontDetails,
    int? nutritionValueCount,
  }) {
    return ManualProductPhotoState(
      front: front ?? this.front,
      nutritionTable: nutritionTable ?? this.nutritionTable,
      isReadingFront: isReadingFront ?? this.isReadingFront,
      isReadingNutritionTable:
          isReadingNutritionTable ?? this.isReadingNutritionTable,
      hasReadFront: hasReadFront ?? this.hasReadFront,
      hasReadNutritionTable:
          hasReadNutritionTable ?? this.hasReadNutritionTable,
      isSaving: isSaving ?? this.isSaving,
      frontDetails: frontDetails ?? this.frontDetails,
      nutritionValueCount: nutritionValueCount ?? this.nutritionValueCount,
    );
  }
}

/// Takes the package photos of the product editor, reads them into the
/// product, and stores them when the product is saved.
///
/// The barcode scanner looks at every photo first. Only when it finds no
/// barcode does the barcode the AI read on the front count.
@riverpod
class ManualProductPhotoController extends _$ManualProductPhotoController {
  @override
  ManualProductPhotoState build(InventoryReceiptManualProductConfig config) {
    return const ManualProductPhotoState();
  }

  InventoryReceiptManualProductController get _product => ref.read(
    inventoryReceiptManualProductControllerProvider(config).notifier,
  );

  /// Takes a photo of the package front and fills name, brand, package
  /// size, and barcode from it.
  Future<ManualProductPhotoOutcome> takeFrontPhoto() async {
    // The other photo may still be read; only this one waits.
    if (state.isReadingFront || state.isSaving) {
      return ManualProductPhotoOutcome.canceled;
    }
    final repository = ref.read(productPhotoRepositoryProvider);
    final taken = await _takePhoto(repository);
    final photo = taken.photo;
    if (photo == null || !ref.mounted) {
      return taken.outcome ?? ManualProductPhotoOutcome.canceled;
    }
    state = state.copyWith(
      front: photo,
      isReadingFront: true,
      hasReadFront: false,
    );
    try {
      await _applyScannedBarcode(repository, photo);
      final details = await repository.loadFrontDetails(photo);
      if (!ref.mounted) return ManualProductPhotoOutcome.canceled;
      _product.applyFrontDetails(details);
      state = state.copyWith(hasReadFront: true, frontDetails: details);
      return ManualProductPhotoOutcome.read;
    } on ProductFrontNotProductException {
      return ManualProductPhotoOutcome.notProduct;
    } on ProductFrontUnreadableException {
      return ManualProductPhotoOutcome.retakePhoto;
    } on Object catch (error, stackTrace) {
      log(
        'Reading the package front failed.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return ManualProductPhotoOutcome.failed;
    } finally {
      if (ref.mounted) state = state.copyWith(isReadingFront: false);
    }
  }

  /// Takes a photo of the nutrition table and fills the values from it.
  Future<ManualProductPhotoOutcome> takeNutritionTablePhoto() async {
    if (state.isReadingNutritionTable || state.isSaving) {
      return ManualProductPhotoOutcome.canceled;
    }
    final repository = ref.read(productPhotoRepositoryProvider);
    final taken = await _takePhoto(repository);
    final photo = taken.photo;
    if (photo == null || !ref.mounted) {
      return taken.outcome ?? ManualProductPhotoOutcome.canceled;
    }
    state = state.copyWith(
      nutritionTable: photo,
      isReadingNutritionTable: true,
      hasReadNutritionTable: false,
    );
    try {
      await _applyScannedBarcode(repository, photo);
      final result = await ref
          .read(nutritionLabelOcrRepositoryProvider)
          .readNutritionLabel(
            imageBytes: photo.bytes,
            mimeType: photo.mimeType,
            barcode: ref
                .read(inventoryReceiptManualProductControllerProvider(config))
                .barcode,
          );
      if (!ref.mounted) return ManualProductPhotoOutcome.canceled;
      final draft = result.draft;
      if (result.status == NutritionLabelOcrStatus.succeeded && draft != null) {
        _product.applyNutritionLabelDraft(draft);
        state = state.copyWith(
          hasReadNutritionTable: true,
          // The seven EU values always come with a read label.
          nutritionValueCount:
              7 +
              [
                draft.per100PolyunsaturatedFat,
                draft.per100Fiber,
              ].nonNulls.length,
        );
        return ManualProductPhotoOutcome.read;
      }
      return switch (result.errorCode) {
        NutritionLabelOcrErrorCodes.appCheckThrottled =>
          ManualProductPhotoOutcome.appCheckThrottled,
        NutritionLabelOcrErrorCodes.retakePhoto =>
          ManualProductPhotoOutcome.retakePhoto,
        _ => ManualProductPhotoOutcome.failed,
      };
    } finally {
      if (ref.mounted) state = state.copyWith(isReadingNutritionTable: false);
    }
  }

  /// Stores the photos as shared product images and returns the address of
  /// the front photo, or null without one.
  ///
  /// Throws when the upload fails.
  Future<String?> savePhotos({
    required String barcode,
    required String name,
  }) async {
    if (!state.hasPhoto) return null;
    state = state.copyWith(isSaving: true);
    try {
      return await ref
          .read(productPhotoRepositoryProvider)
          .saveProductPhotos(
            front: state.front,
            nutritionTable: state.nutritionTable,
            barcode: barcode,
            name: name,
          );
    } finally {
      if (ref.mounted) state = state.copyWith(isSaving: false);
    }
  }

  /// Takes a photo, or tells why there is none.
  Future<({ProductPhoto? photo, ManualProductPhotoOutcome? outcome})>
  _takePhoto(ProductPhotoRepository repository) async {
    try {
      final photo = await repository.loadCameraPhoto();
      return (
        photo: photo,
        outcome: photo == null ? ManualProductPhotoOutcome.canceled : null,
      );
    } on ProductPhotoCameraUnsupportedException {
      return (
        photo: null,
        outcome: ManualProductPhotoOutcome.cameraUnsupported,
      );
    } on Object catch (error, stackTrace) {
      log(
        'Taking a package photo failed.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return (photo: null, outcome: ManualProductPhotoOutcome.failed);
    }
  }

  /// Hands a barcode the scanner finds on [photo] to the product. A photo
  /// without a readable barcode is normal, so a scanner failure only logs.
  Future<void> _applyScannedBarcode(
    ProductPhotoRepository repository,
    ProductPhoto photo,
  ) async {
    try {
      final barcode = await repository.loadBarcode(photo);
      if (barcode != null && ref.mounted) _product.applyPhotoBarcode(barcode);
    } on Object catch (error, stackTrace) {
      log(
        'The barcode scanner could not read the photo.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
