// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_gateway_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for [ReceiptProductResolver].
///
/// Uses [YamtReceiptProductResolver] by default in production.

@ProviderFor(receiptProductResolver)
final receiptProductResolverProvider = ReceiptProductResolverProvider._();

/// Provider for [ReceiptProductResolver].
///
/// Uses [YamtReceiptProductResolver] by default in production.

final class ReceiptProductResolverProvider
    extends
        $FunctionalProvider<
          ReceiptProductResolver,
          ReceiptProductResolver,
          ReceiptProductResolver
        >
    with $Provider<ReceiptProductResolver> {
  /// Provider for [ReceiptProductResolver].
  ///
  /// Uses [YamtReceiptProductResolver] by default in production.
  ReceiptProductResolverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptProductResolverProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptProductResolverHash();

  @$internal
  @override
  $ProviderElement<ReceiptProductResolver> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptProductResolver create(Ref ref) {
    return receiptProductResolver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptProductResolver value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptProductResolver>(value),
    );
  }
}

String _$receiptProductResolverHash() =>
    r'f4f76ebde30b73466fd13119a43892bd5873a3ee';

/// Provider for [ReceiptStorageGateway].
///
/// Uses [YamtReceiptStorageGateway] by default in production.

@ProviderFor(receiptStorageGateway)
final receiptStorageGatewayProvider = ReceiptStorageGatewayProvider._();

/// Provider for [ReceiptStorageGateway].
///
/// Uses [YamtReceiptStorageGateway] by default in production.

final class ReceiptStorageGatewayProvider
    extends
        $FunctionalProvider<
          ReceiptStorageGateway,
          ReceiptStorageGateway,
          ReceiptStorageGateway
        >
    with $Provider<ReceiptStorageGateway> {
  /// Provider for [ReceiptStorageGateway].
  ///
  /// Uses [YamtReceiptStorageGateway] by default in production.
  ReceiptStorageGatewayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptStorageGatewayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptStorageGatewayHash();

  @$internal
  @override
  $ProviderElement<ReceiptStorageGateway> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptStorageGateway create(Ref ref) {
    return receiptStorageGateway(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptStorageGateway value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptStorageGateway>(value),
    );
  }
}

String _$receiptStorageGatewayHash() =>
    r'633f43be1e565d9714b336cc859b25bb55a79dba';

/// Provider for [ReceiptTextExtractor].
///
/// Uses [MlKitReceiptTextExtractor] for on-device OCR by default.
/// Disposes native resources on provider disposal.

@ProviderFor(receiptTextExtractor)
final receiptTextExtractorProvider = ReceiptTextExtractorProvider._();

/// Provider for [ReceiptTextExtractor].
///
/// Uses [MlKitReceiptTextExtractor] for on-device OCR by default.
/// Disposes native resources on provider disposal.

final class ReceiptTextExtractorProvider
    extends
        $FunctionalProvider<
          ReceiptTextExtractor,
          ReceiptTextExtractor,
          ReceiptTextExtractor
        >
    with $Provider<ReceiptTextExtractor> {
  /// Provider for [ReceiptTextExtractor].
  ///
  /// Uses [MlKitReceiptTextExtractor] for on-device OCR by default.
  /// Disposes native resources on provider disposal.
  ReceiptTextExtractorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptTextExtractorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptTextExtractorHash();

  @$internal
  @override
  $ProviderElement<ReceiptTextExtractor> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptTextExtractor create(Ref ref) {
    return receiptTextExtractor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptTextExtractor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptTextExtractor>(value),
    );
  }
}

String _$receiptTextExtractorHash() =>
    r'd0fddae4dd48b351fe1ce6d158d40ffb5a64d7ec';

/// Provider for [ReceiptStructuredParser].
///
/// Uses [GoogleAiReceiptParser] powered by the Google AI API (Gemini Flash).

@ProviderFor(receiptStructuredParser)
final receiptStructuredParserProvider = ReceiptStructuredParserProvider._();

/// Provider for [ReceiptStructuredParser].
///
/// Uses [GoogleAiReceiptParser] powered by the Google AI API (Gemini Flash).

final class ReceiptStructuredParserProvider
    extends
        $FunctionalProvider<
          ReceiptStructuredParser,
          ReceiptStructuredParser,
          ReceiptStructuredParser
        >
    with $Provider<ReceiptStructuredParser> {
  /// Provider for [ReceiptStructuredParser].
  ///
  /// Uses [GoogleAiReceiptParser] powered by the Google AI API (Gemini Flash).
  ReceiptStructuredParserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptStructuredParserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptStructuredParserHash();

  @$internal
  @override
  $ProviderElement<ReceiptStructuredParser> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptStructuredParser create(Ref ref) {
    return receiptStructuredParser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptStructuredParser value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptStructuredParser>(value),
    );
  }
}

String _$receiptStructuredParserHash() =>
    r'14c05444e2393c61c1b1e8a698e97828cc3b6e26';

/// Provider for [ReceiptManualProductPicker].
///
/// Uses [YamtReceiptManualProductPicker] by default in production.

@ProviderFor(receiptManualProductPicker)
final receiptManualProductPickerProvider =
    ReceiptManualProductPickerProvider._();

/// Provider for [ReceiptManualProductPicker].
///
/// Uses [YamtReceiptManualProductPicker] by default in production.

final class ReceiptManualProductPickerProvider
    extends
        $FunctionalProvider<
          ReceiptManualProductPicker,
          ReceiptManualProductPicker,
          ReceiptManualProductPicker
        >
    with $Provider<ReceiptManualProductPicker> {
  /// Provider for [ReceiptManualProductPicker].
  ///
  /// Uses [YamtReceiptManualProductPicker] by default in production.
  ReceiptManualProductPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptManualProductPickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptManualProductPickerHash();

  @$internal
  @override
  $ProviderElement<ReceiptManualProductPicker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptManualProductPicker create(Ref ref) {
    return receiptManualProductPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptManualProductPicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptManualProductPicker>(value),
    );
  }
}

String _$receiptManualProductPickerHash() =>
    r'd149c58a94f5f29b49e51fc7386d1013ef6569e6';
