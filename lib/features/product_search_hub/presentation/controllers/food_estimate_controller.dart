import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/product_search_hub/data/'
    'food_estimate_repository.dart';
import 'package:yamt/features/product_search_hub/domain/food_estimate.dart';

part 'food_estimate_controller.g.dart';

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

  /// Adds [photos] after the existing ones.
  void addPhotos(List<FoodEstimatePhoto> photos) {
    state = state.copyWith(photos: [...state.photos, ...photos]);
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
