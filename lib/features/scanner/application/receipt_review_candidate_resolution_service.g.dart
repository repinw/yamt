// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_review_candidate_resolution_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Receipt review candidate resolution service.

@ProviderFor(receiptReviewCandidateResolutionService)
final receiptReviewCandidateResolutionServiceProvider =
    ReceiptReviewCandidateResolutionServiceProvider._();

/// Receipt review candidate resolution service.

final class ReceiptReviewCandidateResolutionServiceProvider
    extends
        $FunctionalProvider<
          ReceiptReviewCandidateResolutionService,
          ReceiptReviewCandidateResolutionService,
          ReceiptReviewCandidateResolutionService
        >
    with $Provider<ReceiptReviewCandidateResolutionService> {
  /// Receipt review candidate resolution service.
  ReceiptReviewCandidateResolutionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptReviewCandidateResolutionServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$receiptReviewCandidateResolutionServiceHash();

  @$internal
  @override
  $ProviderElement<ReceiptReviewCandidateResolutionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptReviewCandidateResolutionService create(Ref ref) {
    return receiptReviewCandidateResolutionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptReviewCandidateResolutionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<ReceiptReviewCandidateResolutionService>(value),
    );
  }
}

String _$receiptReviewCandidateResolutionServiceHash() =>
    r'21d89e996f43b2255d69af0e81ce953c9cc5237e';
