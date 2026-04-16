// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_weekly_checkin_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Defines calorie weekly check in controller.

@ProviderFor(CalorieWeeklyCheckInController)
final calorieWeeklyCheckInControllerProvider =
    CalorieWeeklyCheckInControllerProvider._();

/// Defines calorie weekly check in controller.
final class CalorieWeeklyCheckInControllerProvider
    extends
        $NotifierProvider<CalorieWeeklyCheckInController, AsyncValue<void>> {
  /// Defines calorie weekly check in controller.
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
    r'69eb57a2b48a781a4566cf4eaf7a941152e203e0';

/// Defines calorie weekly check in controller.

abstract class _$CalorieWeeklyCheckInController
    extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
