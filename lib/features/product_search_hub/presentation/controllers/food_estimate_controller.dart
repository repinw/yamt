import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/product_search_hub/data/'
    'food_estimate_repository.dart';
import 'package:yamt/features/product_search_hub/domain/food_estimate.dart';

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
  });

  /// Photos in the order the user added them.
  final List<FoodEstimatePhoto> photos;

  /// The latest estimate; loading while the AI works.
  final AsyncValue<FoodEstimate?> estimate;

  /// Whether another photo fits.
  bool get canAddPhoto => photos.length < foodEstimateMaxPhotos;

  /// Copies the state.
  FoodEstimateState copyWith({
    List<FoodEstimatePhoto>? photos,
    AsyncValue<FoodEstimate?>? estimate,
  }) {
    return FoodEstimateState(
      photos: photos ?? this.photos,
      estimate: estimate ?? this.estimate,
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

  /// Stores the first photo as the user's private food photo and returns
  /// its address, or null without a photo. Throws when the upload fails.
  Future<String?> saveFirstPhoto() async {
    final photo = state.photos.firstOrNull;
    if (photo == null) return null;
    return await ref.read(foodEstimateRepositoryProvider).saveFoodPhoto(photo);
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
