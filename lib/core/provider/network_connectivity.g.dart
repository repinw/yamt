// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_connectivity.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The platform's connectivity plugin. Tests replace it with a fake.

@ProviderFor(connectivity)
final connectivityProvider = ConnectivityProvider._();

/// The platform's connectivity plugin. Tests replace it with a fake.

final class ConnectivityProvider
    extends $FunctionalProvider<Connectivity, Connectivity, Connectivity>
    with $Provider<Connectivity> {
  /// The platform's connectivity plugin. Tests replace it with a fake.
  ConnectivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivityHash();

  @$internal
  @override
  $ProviderElement<Connectivity> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Connectivity create(Ref ref) {
    return connectivity(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Connectivity value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Connectivity>(value),
    );
  }
}

String _$connectivityHash() => r'e66720f09edf1a8b09e450e1eaedd51da9443f0e';

/// Whether the device is offline, first as checked at start and then on
/// every change that lasts [connectivitySettleDelay]. It emits only when
/// the state flips.
///
/// The platform reports the network connections of the device (Wi-Fi,
/// mobile data, Ethernet, ...), not whether a server answers. Wi-Fi without
/// internet therefore counts as online; flight mode without Wi-Fi is
/// offline.

@ProviderFor(deviceOffline)
final deviceOfflineProvider = DeviceOfflineProvider._();

/// Whether the device is offline, first as checked at start and then on
/// every change that lasts [connectivitySettleDelay]. It emits only when
/// the state flips.
///
/// The platform reports the network connections of the device (Wi-Fi,
/// mobile data, Ethernet, ...), not whether a server answers. Wi-Fi without
/// internet therefore counts as online; flight mode without Wi-Fi is
/// offline.

final class DeviceOfflineProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Whether the device is offline, first as checked at start and then on
  /// every change that lasts [connectivitySettleDelay]. It emits only when
  /// the state flips.
  ///
  /// The platform reports the network connections of the device (Wi-Fi,
  /// mobile data, Ethernet, ...), not whether a server answers. Wi-Fi without
  /// internet therefore counts as online; flight mode without Wi-Fi is
  /// offline.
  DeviceOfflineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceOfflineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceOfflineHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return deviceOffline(ref);
  }
}

String _$deviceOfflineHash() => r'3773d9a0b27c1421269965c51197e5abe4b9b420';
