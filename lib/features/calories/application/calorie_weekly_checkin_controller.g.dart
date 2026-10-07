// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_weekly_checkin_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Defines calorie weekly check in controller.
///
/// Diary dialog callbacks capture this notifier, so every action keeps this
/// controller and the goal controller alive until it ends.

@ProviderFor(CalorieWeeklyCheckInController)
final calorieWeeklyCheckInControllerProvider =
    CalorieWeeklyCheckInControllerProvider._();

/// Defines calorie weekly check in controller.
///
/// Diary dialog callbacks capture this notifier, so every action keeps this
/// controller and the goal controller alive until it ends.
final class CalorieWeeklyCheckInControllerProvider
    extends
        $NotifierProvider<CalorieWeeklyCheckInController, AsyncValue<void>> {
  /// Defines calorie weekly check in controller.
  ///
  /// Diary dialog callbacks capture this notifier, so every action keeps this
  /// controller and the goal controller alive until it ends.
  CalorieWeeklyCheckInControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieWeeklyCheckInControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieWeeklyCheckInControllerHash();

  @$internal
  @override
  CalorieWeeklyCheckInController create() => CalorieWeeklyCheckInController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$calorieWeeklyCheckInControllerHash() =>
    r'3e8768af6a9972f24589d8c9e81499a5e3f4d30b';

/// Defines calorie weekly check in controller.
///
/// Diary dialog callbacks capture this notifier, so every action keeps this
/// controller and the goal controller alive until it ends.

abstract class _$CalorieWeeklyCheckInController
    extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
