// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_weight_cloud_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Copies the Health weights of this device to the cloud, so every device
/// of the user computes with the same weights.
///
/// The diary keeps it running once the diary has its data; it runs again on
/// resume, on a new day, and when the first goal moves. It copies the
/// weights from the start of the first goal on, also those this app wrote to
/// Health: with Health ready, a manual weight is stored only there. A failed
/// sync is logged and waits for the next run.

@ProviderFor(healthWeightCloudSync)
final healthWeightCloudSyncProvider = HealthWeightCloudSyncProvider._();

/// Copies the Health weights of this device to the cloud, so every device
/// of the user computes with the same weights.
///
/// The diary keeps it running once the diary has its data; it runs again on
/// resume, on a new day, and when the first goal moves. It copies the
/// weights from the start of the first goal on, also those this app wrote to
/// Health: with Health ready, a manual weight is stored only there. A failed
/// sync is logged and waits for the next run.

final class HealthWeightCloudSyncProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Copies the Health weights of this device to the cloud, so every device
  /// of the user computes with the same weights.
  ///
  /// The diary keeps it running once the diary has its data; it runs again on
  /// resume, on a new day, and when the first goal moves. It copies the
  /// weights from the start of the first goal on, also those this app wrote to
  /// Health: with Health ready, a manual weight is stored only there. A failed
  /// sync is logged and waits for the next run.
  HealthWeightCloudSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthWeightCloudSyncProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthWeightCloudSyncHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return healthWeightCloudSync(ref);
  }
}

String _$healthWeightCloudSyncHash() =>
    r'1b94b3e954eb30fee630cdca52001b9f3571f593';
