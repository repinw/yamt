// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_analysis_clients.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(receiptTemplateConfigClient)
final receiptTemplateConfigClientProvider =
    ReceiptTemplateConfigClientProvider._();

final class ReceiptTemplateConfigClientProvider
    extends
        $FunctionalProvider<
          ReceiptTemplateConfigClient,
          ReceiptTemplateConfigClient,
          ReceiptTemplateConfigClient
        >
    with $Provider<ReceiptTemplateConfigClient> {
  ReceiptTemplateConfigClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptTemplateConfigClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptTemplateConfigClientHash();

  @$internal
  @override
  $ProviderElement<ReceiptTemplateConfigClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptTemplateConfigClient create(Ref ref) {
    return receiptTemplateConfigClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptTemplateConfigClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptTemplateConfigClient>(value),
    );
  }
}

String _$receiptTemplateConfigClientHash() =>
    r'136ad034437c6e8bbeaedeed1cc1f1044e4e760d';

@ProviderFor(receiptTemplateModelClient)
final receiptTemplateModelClientProvider =
    ReceiptTemplateModelClientProvider._();

final class ReceiptTemplateModelClientProvider
    extends
        $FunctionalProvider<
          ReceiptTemplateModelClient,
          ReceiptTemplateModelClient,
          ReceiptTemplateModelClient
        >
    with $Provider<ReceiptTemplateModelClient> {
  ReceiptTemplateModelClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptTemplateModelClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptTemplateModelClientHash();

  @$internal
  @override
  $ProviderElement<ReceiptTemplateModelClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptTemplateModelClient create(Ref ref) {
    return receiptTemplateModelClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptTemplateModelClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptTemplateModelClient>(value),
    );
  }
}

String _$receiptTemplateModelClientHash() =>
    r'211cbbb40417ca83311b232d82ae9ebfb49acdc8';
