// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_weekly_checkin_success_dismissal_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Day key of the weekly check-in whose success message the user closed, so
/// the message stays closed for that check-in. Saved on the device.

@ProviderFor(DiaryWeeklyCheckInSuccessDismissalController)
final diaryWeeklyCheckInSuccessDismissalControllerProvider =
    DiaryWeeklyCheckInSuccessDismissalControllerProvider._();

/// Day key of the weekly check-in whose success message the user closed, so
/// the message stays closed for that check-in. Saved on the device.
final class DiaryWeeklyCheckInSuccessDismissalControllerProvider
    extends
        $NotifierProvider<
          DiaryWeeklyCheckInSuccessDismissalController,
          String?
        > {
  /// Day key of the weekly check-in whose success message the user closed, so
  /// the message stays closed for that check-in. Saved on the device.
  DiaryWeeklyCheckInSuccessDismissalControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryWeeklyCheckInSuccessDismissalControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$diaryWeeklyCheckInSuccessDismissalControllerHash();

  @$internal
  @override
  DiaryWeeklyCheckInSuccessDismissalController create() =>
      DiaryWeeklyCheckInSuccessDismissalController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$diaryWeeklyCheckInSuccessDismissalControllerHash() =>
    r'142c92eb02dc29fb070d4db8c3c1d98084a16375';

/// Day key of the weekly check-in whose success message the user closed, so
/// the message stays closed for that check-in. Saved on the device.

abstract class _$DiaryWeeklyCheckInSuccessDismissalController
    extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
