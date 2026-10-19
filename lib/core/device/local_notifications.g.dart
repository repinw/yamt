// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_notifications.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifications of the current platform. Kept alive, so the tap stream
/// and the plugin are set up once.

@ProviderFor(localNotifications)
final localNotificationsProvider = LocalNotificationsProvider._();

/// Notifications of the current platform. Kept alive, so the tap stream
/// and the plugin are set up once.

final class LocalNotificationsProvider
    extends
        $FunctionalProvider<
          LocalNotifications,
          LocalNotifications,
          LocalNotifications
        >
    with $Provider<LocalNotifications> {
  /// Notifications of the current platform. Kept alive, so the tap stream
  /// and the plugin are set up once.
  LocalNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localNotificationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localNotificationsHash();

  @$internal
  @override
  $ProviderElement<LocalNotifications> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalNotifications create(Ref ref) {
    return localNotifications(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalNotifications value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalNotifications>(value),
    );
  }
}

String _$localNotificationsHash() =>
    r'db8b1ef22cc1e5aed99b85c5102366ae77a73665';

/// Whether the system lets the app show notifications on [channelId].
/// Checks again whenever the app returns to the foreground: the user may
/// have changed it in the system settings.

@ProviderFor(localNotificationsAllowed)
final localNotificationsAllowedProvider = LocalNotificationsAllowedFamily._();

/// Whether the system lets the app show notifications on [channelId].
/// Checks again whenever the app returns to the foreground: the user may
/// have changed it in the system settings.

final class LocalNotificationsAllowedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the system lets the app show notifications on [channelId].
  /// Checks again whenever the app returns to the foreground: the user may
  /// have changed it in the system settings.
  LocalNotificationsAllowedProvider._({
    required LocalNotificationsAllowedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'localNotificationsAllowedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$localNotificationsAllowedHash();

  @override
  String toString() {
    return r'localNotificationsAllowedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return localNotificationsAllowed(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LocalNotificationsAllowedProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$localNotificationsAllowedHash() =>
    r'd484d8aa51d9a7bc9dd67c1c93d0511cd03b410f';

/// Whether the system lets the app show notifications on [channelId].
/// Checks again whenever the app returns to the foreground: the user may
/// have changed it in the system settings.

final class LocalNotificationsAllowedFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  LocalNotificationsAllowedFamily._()
    : super(
        retry: null,
        name: r'localNotificationsAllowedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether the system lets the app show notifications on [channelId].
  /// Checks again whenever the app returns to the foreground: the user may
  /// have changed it in the system settings.

  LocalNotificationsAllowedProvider call(String channelId) =>
      LocalNotificationsAllowedProvider._(argument: channelId, from: this);

  @override
  String toString() => r'localNotificationsAllowedProvider';
}
