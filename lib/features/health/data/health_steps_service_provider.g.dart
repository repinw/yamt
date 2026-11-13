// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_steps_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Health steps service.

@ProviderFor(healthStepsService)
final healthStepsServiceProvider = HealthStepsServiceProvider._();

/// Health steps service.

final class HealthStepsServiceProvider
    extends
        $FunctionalProvider<
          HealthStepsService,
          HealthStepsService,
          HealthStepsService
        >
    with $Provider<HealthStepsService> {
  /// Health steps service.
  HealthStepsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthStepsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthStepsServiceHash();

  @$internal
  @override
  $ProviderElement<HealthStepsService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HealthStepsService create(Ref ref) {
    return healthStepsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthStepsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthStepsService>(value),
    );
  }
}

String _$healthStepsServiceHash() =>
    r'50991fb431eac36b940366b0366464bb85747447';
