// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_app_weight_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Writes and deletes the weighings that this app keeps in Health.

@ProviderFor(healthAppWeightService)
final healthAppWeightServiceProvider = HealthAppWeightServiceProvider._();

/// Writes and deletes the weighings that this app keeps in Health.

final class HealthAppWeightServiceProvider
    extends
        $FunctionalProvider<
          HealthAppWeightService,
          HealthAppWeightService,
          HealthAppWeightService
        >
    with $Provider<HealthAppWeightService> {
  /// Writes and deletes the weighings that this app keeps in Health.
  HealthAppWeightServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthAppWeightServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthAppWeightServiceHash();

  @$internal
  @override
  $ProviderElement<HealthAppWeightService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HealthAppWeightService create(Ref ref) {
    return healthAppWeightService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthAppWeightService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthAppWeightService>(value),
    );
  }
}

String _$healthAppWeightServiceHash() =>
    r'e8b6e4d307d9de3ac504e469ee00403c1bd8dea2';
