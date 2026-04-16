// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_analysis_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Receipt analysis repository.

@ProviderFor(receiptAnalysisRepository)
final receiptAnalysisRepositoryProvider = ReceiptAnalysisRepositoryProvider._();

/// Receipt analysis repository.

final class ReceiptAnalysisRepositoryProvider
    extends
        $FunctionalProvider<
          ReceiptAnalysisRepository,
          ReceiptAnalysisRepository,
          ReceiptAnalysisRepository
        >
    with $Provider<ReceiptAnalysisRepository> {
  /// Receipt analysis repository.
  ReceiptAnalysisRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptAnalysisRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptAnalysisRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReceiptAnalysisRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptAnalysisRepository create(Ref ref) {
    return receiptAnalysisRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptAnalysisRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptAnalysisRepository>(value),
    );
  }
}

String _$receiptAnalysisRepositoryHash() =>
    r'b179b8122c1239f374078e98deeb3f23be54a2d3';
