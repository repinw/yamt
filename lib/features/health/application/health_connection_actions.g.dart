// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_connection_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Exposes Health connection state to consuming application layers.

@ProviderFor(healthConnectionStatus)
final healthConnectionStatusProvider = HealthConnectionStatusProvider._();

/// Exposes Health connection state to consuming application layers.

final class HealthConnectionStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<HealthConnectionStatus>,
          HealthConnectionStatus,
          FutureOr<HealthConnectionStatus>
        >
    with
        $FutureModifier<HealthConnectionStatus>,
        $FutureProvider<HealthConnectionStatus> {
  /// Exposes Health connection state to consuming application layers.
  HealthConnectionStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthConnectionStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthConnectionStatusHash();

  @$internal
  @override
  $FutureProviderElement<HealthConnectionStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HealthConnectionStatus> create(Ref ref) {
    return healthConnectionStatus(ref);
  }
}

String _$healthConnectionStatusHash() =>
    r'59f2bd3b267d2a86907154d09ee9badc3df8d263';

/// Exposes Health connection actions without exposing its controller.

@ProviderFor(healthConnectionActions)
final healthConnectionActionsProvider = HealthConnectionActionsProvider._();

/// Exposes Health connection actions without exposing its controller.

final class HealthConnectionActionsProvider
    extends
        $FunctionalProvider<
          HealthConnectionActions,
          HealthConnectionActions,
          HealthConnectionActions
        >
    with $Provider<HealthConnectionActions> {
  /// Exposes Health connection actions without exposing its controller.
  HealthConnectionActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthConnectionActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthConnectionActionsHash();

  @$internal
  @override
  $ProviderElement<HealthConnectionActions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HealthConnectionActions create(Ref ref) {
    return healthConnectionActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthConnectionActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthConnectionActions>(value),
    );
  }
}

String _$healthConnectionActionsHash() =>
    r'05fdd111322e954d0ab8ec4f41d4d0de3f8a3c6d';
