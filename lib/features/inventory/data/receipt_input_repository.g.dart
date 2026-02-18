// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_input_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(receiptInputRepository)
final receiptInputRepositoryProvider = ReceiptInputRepositoryProvider._();

final class ReceiptInputRepositoryProvider
    extends
        $FunctionalProvider<
          ReceiptInputRepository,
          ReceiptInputRepository,
          ReceiptInputRepository
        >
    with $Provider<ReceiptInputRepository> {
  ReceiptInputRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptInputRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptInputRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReceiptInputRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptInputRepository create(Ref ref) {
    return receiptInputRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptInputRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptInputRepository>(value),
    );
  }
}

String _$receiptInputRepositoryHash() =>
    r'bdbe44b861541ba8ad02238ad4d4a8e62fbcd0ef';
