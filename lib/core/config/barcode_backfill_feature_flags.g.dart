// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'barcode_backfill_feature_flags.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves barcode backfill feature flags from Firebase Remote Config.

@ProviderFor(barcodeBackfillFeatureFlags)
final barcodeBackfillFeatureFlagsProvider =
    BarcodeBackfillFeatureFlagsProvider._();

/// Resolves barcode backfill feature flags from Firebase Remote Config.

final class BarcodeBackfillFeatureFlagsProvider
    extends
        $FunctionalProvider<
          BarcodeBackfillFeatureFlags,
          BarcodeBackfillFeatureFlags,
          BarcodeBackfillFeatureFlags
        >
    with $Provider<BarcodeBackfillFeatureFlags> {
  /// Resolves barcode backfill feature flags from Firebase Remote Config.
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
    r'5c0472f72ecae8fe9f86ebfa0460a59c96fcd631';
