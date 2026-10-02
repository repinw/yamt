import 'package:yamt/features/product_search_hub/domain/product_photo.dart';

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

  /// Whether the photo upload is starting.
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
