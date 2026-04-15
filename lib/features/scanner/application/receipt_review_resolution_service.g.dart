// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_review_resolution_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(receiptReviewResolutionService)
final receiptReviewResolutionServiceProvider =
    ReceiptReviewResolutionServiceProvider._();

final class ReceiptReviewResolutionServiceProvider
    extends
        $FunctionalProvider<
          ReceiptReviewResolutionService,
          ReceiptReviewResolutionService,
          ReceiptReviewResolutionService
        >
    with $Provider<ReceiptReviewResolutionService> {
  ReceiptReviewResolutionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptReviewResolutionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptReviewResolutionServiceHash();

  @$internal
  @override
  $ProviderElement<ReceiptReviewResolutionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptReviewResolutionService create(Ref ref) {
    return receiptReviewResolutionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptReviewResolutionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptReviewResolutionService>(
        value,
      ),
    );
  }
}

String _$receiptReviewResolutionServiceHash() =>
    r'f84337e13b23a9a3bb1a87ea7260f9f66de25c0d';
