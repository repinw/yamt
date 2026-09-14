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
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
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
    r'5d0a689ca4ba271f85b30ca95a0ccd9cc6e6e1a6';

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
        dependencies: <ProviderOrFamily>[inventoryItemRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ReceiptStorageGatewayProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = inventoryItemRepositoryProvider;

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
    r'0969eb3ef4b6fb51824153e791b0310adc8626ec';

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
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
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
    r'5aa7dc91d1470d7918dd0b86cdcad6c1f44645de';

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
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
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
    r'a9c5c0f2d6b6335d1effe5b607f9766789f8d4cb';

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
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
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
    r'0fe8c91b5d90416d5c7e35f38840d1fdac43dd96';
