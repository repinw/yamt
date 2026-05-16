// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_weight_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Health weight service.

@ProviderFor(healthWeightService)
final healthWeightServiceProvider = HealthWeightServiceProvider._();

/// Health weight service.

final class HealthWeightServiceProvider
    extends
        $FunctionalProvider<
          HealthWeightService,
          HealthWeightService,
          HealthWeightService
        >
    with $Provider<HealthWeightService> {
  /// Health weight service.
  HealthWeightServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthWeightServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthWeightServiceHash();

  @$internal
  @override
  $ProviderElement<HealthWeightService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HealthWeightService create(Ref ref) {
    return healthWeightService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthWeightService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthWeightService>(value),
    );
  }
}

String _$healthWeightServiceHash() =>
    r'e7848875c009c8eb10690802dade80f46b7fa1ff';
