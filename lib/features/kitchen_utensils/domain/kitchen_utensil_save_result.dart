/// Kitchen utensil save failure reason.
enum KitchenUtensilSaveFailureReason {
  /// Invalid form input.
  invalidInput,

  /// Image upload failed.
  imageUploadFailed,

  /// Metadata save failed.
  saveFailed,
}

/// Kitchen utensil save result.
class KitchenUtensilSaveResult {
  const KitchenUtensilSaveResult._({
    required this.isSuccess,
    this.utensilId,
    this.failureReason,
  });

  /// Successful save.
  const KitchenUtensilSaveResult.success(String utensilId)
    : this._(isSuccess: true, utensilId: utensilId);

  /// Failed save.
  const KitchenUtensilSaveResult.failure(
    KitchenUtensilSaveFailureReason reason,
  ) : this._(isSuccess: false, failureReason: reason);

  /// Whether save succeeded.
  final bool isSuccess;

  /// Saved utensil id.
  final String? utensilId;

  /// Failure reason.
  final KitchenUtensilSaveFailureReason? failureReason;
}
