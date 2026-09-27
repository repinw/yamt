/// Failures in the product search hub that the user can act on.
sealed class ProductSearchHubException implements Exception {
  const new();
}

/// Failures of an AI food estimate.
sealed class FoodEstimateException extends ProductSearchHubException {
  const new();
}

/// The photos and the description show no food.
final class FoodEstimateNotFoodException extends FoodEstimateException {
  /// Creates the exception.
  const new();
}

/// Nothing could be identified: the photos are too dark or blurred, and the
/// description names no food.
final class FoodEstimateUnclearException extends FoodEstimateException {
  /// Creates the exception.
  const new();
}
