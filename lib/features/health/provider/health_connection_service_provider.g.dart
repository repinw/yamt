// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_connection_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Health connection service.

@ProviderFor(healthConnectionService)
final healthConnectionServiceProvider = HealthConnectionServiceProvider._();

/// Health connection service.

final class HealthConnectionServiceProvider
    extends
        $FunctionalProvider<
          HealthConnectionService,
          HealthConnectionService,
          HealthConnectionService
        >
    with $Provider<HealthConnectionService> {
  /// Health connection service.
  HealthConnectionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthConnectionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthConnectionServiceHash();

  @$internal
  @override
  $ProviderElement<HealthConnectionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HealthConnectionService create(Ref ref) {
    return healthConnectionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthConnectionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthConnectionService>(value),
    );
  }
}

String _$healthConnectionServiceHash() =>
    r'23a69eddcab7a9b051017e938958028c32ae6643';
