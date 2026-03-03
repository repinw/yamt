// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'barcode_backfill_feature_flags.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(barcodeBackfillFeatureFlags)
final barcodeBackfillFeatureFlagsProvider =
    BarcodeBackfillFeatureFlagsProvider._();

final class BarcodeBackfillFeatureFlagsProvider
    extends
        $FunctionalProvider<
          BarcodeBackfillFeatureFlags,
          BarcodeBackfillFeatureFlags,
          BarcodeBackfillFeatureFlags
        >
    with $Provider<BarcodeBackfillFeatureFlags> {
  BarcodeBackfillFeatureFlagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'barcodeBackfillFeatureFlagsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$barcodeBackfillFeatureFlagsHash();

  @$internal
  @override
  $ProviderElement<BarcodeBackfillFeatureFlags> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BarcodeBackfillFeatureFlags create(Ref ref) {
    return barcodeBackfillFeatureFlags(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BarcodeBackfillFeatureFlags value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BarcodeBackfillFeatureFlags>(value),
    );
  }
}

String _$barcodeBackfillFeatureFlagsHash() =>
    r'7535de600444fb68e735f38779cde756c34808f5';
