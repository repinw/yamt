// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_to_review_item_draft_mapper.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Receipt to review item draft mapper.

@ProviderFor(receiptToReviewItemDraftMapper)
final receiptToReviewItemDraftMapperProvider =
    ReceiptToReviewItemDraftMapperProvider._();

/// Receipt to review item draft mapper.

final class ReceiptToReviewItemDraftMapperProvider
    extends
        $FunctionalProvider<
          ReceiptToReviewItemDraftMapper,
          ReceiptToReviewItemDraftMapper,
          ReceiptToReviewItemDraftMapper
        >
    with $Provider<ReceiptToReviewItemDraftMapper> {
  /// Receipt to review item draft mapper.
  ReceiptToReviewItemDraftMapperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptToReviewItemDraftMapperProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptToReviewItemDraftMapperHash();

  @$internal
  @override
  $ProviderElement<ReceiptToReviewItemDraftMapper> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptToReviewItemDraftMapper create(Ref ref) {
    return receiptToReviewItemDraftMapper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptToReviewItemDraftMapper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptToReviewItemDraftMapper>(
        value,
      ),
    );
  }
}

String _$receiptToReviewItemDraftMapperHash() =>
    r'd0e713ba38ad789bfddee84f7fc8f24b1c296ddd';
