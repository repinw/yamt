// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_ai_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Receipt AI repository.

@ProviderFor(receiptAiRepository)
final receiptAiRepositoryProvider = ReceiptAiRepositoryProvider._();

/// Receipt AI repository.

final class ReceiptAiRepositoryProvider
    extends
        $FunctionalProvider<
          ReceiptAiRepository,
          ReceiptAiRepository,
          ReceiptAiRepository
        >
    with $Provider<ReceiptAiRepository> {
  /// Receipt AI repository.
  ReceiptAiRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptAiRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptAiRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReceiptAiRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptAiRepository create(Ref ref) {
    return receiptAiRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptAiRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptAiRepository>(value),
    );
  }
}

String _$receiptAiRepositoryHash() =>
    r'62da04f8dda8be10b0c429c22fd5a2358a7a84fd';
