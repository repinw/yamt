// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_timer_alarm_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps the notifications of the cook timers this device started in line
/// with the household's cook runs. At the start of cooking
/// ([askPermissions]) it asks once per device for the notification
/// permission, and for exact alarms at every start until Android allows them
/// or the cook came back from the system screen without allowing them. When
/// cooking goes on with a running run, it asks for the notification
/// permission only. The first timer it rings asks for that too, never for
/// exact alarms: those do not open the system screen mid-step.

@ProviderFor(CookTimerAlarmController)
final cookTimerAlarmControllerProvider = CookTimerAlarmControllerProvider._();

/// Keeps the notifications of the cook timers this device started in line
/// with the household's cook runs. At the start of cooking
/// ([askPermissions]) it asks once per device for the notification
/// permission, and for exact alarms at every start until Android allows them
/// or the cook came back from the system screen without allowing them. When
/// cooking goes on with a running run, it asks for the notification
/// permission only. The first timer it rings asks for that too, never for
/// exact alarms: those do not open the system screen mid-step.
final class CookTimerAlarmControllerProvider
    extends $NotifierProvider<CookTimerAlarmController, void> {
  /// Keeps the notifications of the cook timers this device started in line
  /// with the household's cook runs. At the start of cooking
  /// ([askPermissions]) it asks once per device for the notification
  /// permission, and for exact alarms at every start until Android allows them
  /// or the cook came back from the system screen without allowing them. When
  /// cooking goes on with a running run, it asks for the notification
  /// permission only. The first timer it rings asks for that too, never for
  /// exact alarms: those do not open the system screen mid-step.
  CookTimerAlarmControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookTimerAlarmControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookTimerAlarmControllerHash();

  @$internal
  @override
  CookTimerAlarmController create() => CookTimerAlarmController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$cookTimerAlarmControllerHash() =>
    r'e56fbf7d9c6fab8f8d64e9dd8eb1a0f6ec5f7bd9';

/// Keeps the notifications of the cook timers this device started in line
/// with the household's cook runs. At the start of cooking
/// ([askPermissions]) it asks once per device for the notification
/// permission, and for exact alarms at every start until Android allows them
/// or the cook came back from the system screen without allowing them. When
/// cooking goes on with a running run, it asks for the notification
/// permission only. The first timer it rings asks for that too, never for
/// exact alarms: those do not open the system screen mid-step.

abstract class _$CookTimerAlarmController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether cook timers ring on time: Android allows exact alarms ("Alarms &
/// reminders"); always on iOS. Checks again whenever the app returns to the
/// foreground, since the user may change it in the system settings.

@ProviderFor(cookTimerExactAllowed)
final cookTimerExactAllowedProvider = CookTimerExactAllowedProvider._();

/// Whether cook timers ring on time: Android allows exact alarms ("Alarms &
/// reminders"); always on iOS. Checks again whenever the app returns to the
/// foreground, since the user may change it in the system settings.

final class CookTimerExactAllowedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether cook timers ring on time: Android allows exact alarms ("Alarms &
  /// reminders"); always on iOS. Checks again whenever the app returns to the
  /// foreground, since the user may change it in the system settings.
  CookTimerExactAllowedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookTimerExactAllowedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookTimerExactAllowedHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return cookTimerExactAllowed(ref);
  }
}

String _$cookTimerExactAllowedHash() =>
    r'15b0ed5a8fc3d338a58b0a3f5b0e644c24fd28d8';

/// Whether the system blocks the cook timer notifications: they are off or
/// their channel is muted. Only once this device asked for the permission,
/// since the system has no answer before; false while it checks and when
/// the check fails, so no hint shows then.

@ProviderFor(cookTimerNotificationsBlocked)
final cookTimerNotificationsBlockedProvider =
    CookTimerNotificationsBlockedProvider._();

/// Whether the system blocks the cook timer notifications: they are off or
/// their channel is muted. Only once this device asked for the permission,
/// since the system has no answer before; false while it checks and when
/// the check fails, so no hint shows then.

final class CookTimerNotificationsBlockedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the system blocks the cook timer notifications: they are off or
  /// their channel is muted. Only once this device asked for the permission,
  /// since the system has no answer before; false while it checks and when
  /// the check fails, so no hint shows then.
  CookTimerNotificationsBlockedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookTimerNotificationsBlockedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookTimerNotificationsBlockedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return cookTimerNotificationsBlocked(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$cookTimerNotificationsBlockedHash() =>
    r'3da8b9e65dd9c5d9cc0fb917069314177479a877';
