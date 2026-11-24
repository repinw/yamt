// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_pace_notification_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether a notice comes at the start of each part of the day when kcal are
/// free, saved on the device. Off until the user turns it on in the budget
/// card's menu; it only works while the pace marker is on.

@ProviderFor(DiaryPaceNotificationController)
final diaryPaceNotificationControllerProvider =
    DiaryPaceNotificationControllerProvider._();

/// Whether a notice comes at the start of each part of the day when kcal are
/// free, saved on the device. Off until the user turns it on in the budget
/// card's menu; it only works while the pace marker is on.
final class DiaryPaceNotificationControllerProvider
    extends $NotifierProvider<DiaryPaceNotificationController, bool> {
  /// Whether a notice comes at the start of each part of the day when kcal are
  /// free, saved on the device. Off until the user turns it on in the budget
  /// card's menu; it only works while the pace marker is on.
  DiaryPaceNotificationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryPaceNotificationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryPaceNotificationControllerHash();

  @$internal
  @override
  DiaryPaceNotificationController create() => DiaryPaceNotificationController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$diaryPaceNotificationControllerHash() =>
    r'd745b595b2ac453995fed3e4e212502df4f88c5a';

/// Whether a notice comes at the start of each part of the day when kcal are
/// free, saved on the device. Off until the user turns it on in the budget
/// card's menu; it only works while the pace marker is on.

abstract class _$DiaryPaceNotificationController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether the system blocks the pace notices while they are on: the app's
/// notifications are off or their channel is muted. False while the check
/// runs or fails: the notices still try to show.

@ProviderFor(diaryPaceNotificationBlocked)
final diaryPaceNotificationBlockedProvider =
    DiaryPaceNotificationBlockedProvider._();

/// Whether the system blocks the pace notices while they are on: the app's
/// notifications are off or their channel is muted. False while the check
/// runs or fails: the notices still try to show.

final class DiaryPaceNotificationBlockedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the system blocks the pace notices while they are on: the app's
  /// notifications are off or their channel is muted. False while the check
  /// runs or fails: the notices still try to show.
  DiaryPaceNotificationBlockedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryPaceNotificationBlockedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryPaceNotificationBlockedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return diaryPaceNotificationBlocked(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$diaryPaceNotificationBlockedHash() =>
    r'1016bc8dc9d491eb16a218c9375b0981a2b1b21d';
