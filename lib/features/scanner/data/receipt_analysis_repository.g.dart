// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_analysis_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(receiptAnalysisRepository)
final receiptAnalysisRepositoryProvider = ReceiptAnalysisRepositoryProvider._();

final class ReceiptAnalysisRepositoryProvider
    extends
        $FunctionalProvider<
          ReceiptAnalysisRepository,
          ReceiptAnalysisRepository,
          ReceiptAnalysisRepository
        >
    with $Provider<ReceiptAnalysisRepository> {
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
    r'73f63a0d04b92d71a37117749199578d14171a1b';
