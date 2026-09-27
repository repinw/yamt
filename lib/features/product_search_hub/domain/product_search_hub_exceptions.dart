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

/// Failures of reading the front of a package.
sealed class ProductFrontException extends ProductSearchHubException {
  const new();
}

/// The photo shows no food package.
final class ProductFrontNotProductException extends ProductFrontException {
  /// Creates the exception.
  const new();
}

/// The product name on the photo cannot be read.
final class ProductFrontUnreadableException extends ProductFrontException {
  /// Creates the exception.
  const new();
}

/// This device cannot take photos.
final class ProductPhotoCameraUnsupportedException
    extends ProductSearchHubException {
  /// Creates the exception.
  const new();
}
