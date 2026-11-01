// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_pace_notification_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether a notice comes when the pace marker frees a meal's kcal again,
/// saved on the device. Off until the user turns it on in the budget card's
/// menu; it only works while the pace marker is on.

@ProviderFor(DiaryPaceNotificationController)
final diaryPaceNotificationControllerProvider =
    DiaryPaceNotificationControllerProvider._();

/// Whether a notice comes when the pace marker frees a meal's kcal again,
/// saved on the device. Off until the user turns it on in the budget card's
/// menu; it only works while the pace marker is on.
final class DiaryPaceNotificationControllerProvider
    extends $NotifierProvider<DiaryPaceNotificationController, bool> {
  /// Whether a notice comes when the pace marker frees a meal's kcal again,
  /// saved on the device. Off until the user turns it on in the budget card's
  /// menu; it only works while the pace marker is on.
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
    r'886fd88f28e60c81dc735b0ab9d84ff463748288';

/// Whether a notice comes when the pace marker frees a meal's kcal again,
/// saved on the device. Off until the user turns it on in the budget card's
/// menu; it only works while the pace marker is on.

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

/// What today's pace notices need; null while they are off, the pace
/// marker is off, today loads, or today is a pause day.

@ProviderFor(diaryPaceNoticeDay)
final diaryPaceNoticeDayProvider = DiaryPaceNoticeDayProvider._();

/// What today's pace notices need; null while they are off, the pace
/// marker is off, today loads, or today is a pause day.

final class DiaryPaceNoticeDayProvider
    extends $FunctionalProvider<DiaryPaceDay?, DiaryPaceDay?, DiaryPaceDay?>
    with $Provider<DiaryPaceDay?> {
  /// What today's pace notices need; null while they are off, the pace
  /// marker is off, today loads, or today is a pause day.
  DiaryPaceNoticeDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryPaceNoticeDayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryPaceNoticeDayHash();

  @$internal
  @override
  $ProviderElement<DiaryPaceDay?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DiaryPaceDay? create(Ref ref) {
    return diaryPaceNoticeDay(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryPaceDay? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryPaceDay?>(value),
    );
  }
}

String _$diaryPaceNoticeDayHash() =>
    r'bbeb34b76b96311f272a432697951a44a705c38b';

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
