// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_meal_times_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// When the user's day starts and by when they eat each meal, saved on the
/// device.

@ProviderFor(DiaryMealTimesController)
final diaryMealTimesControllerProvider = DiaryMealTimesControllerProvider._();

/// When the user's day starts and by when they eat each meal, saved on the
/// device.
final class DiaryMealTimesControllerProvider
    extends $NotifierProvider<DiaryMealTimesController, DiaryMealTimes> {
  /// When the user's day starts and by when they eat each meal, saved on the
  /// device.
  DiaryMealTimesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryMealTimesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryMealTimesControllerHash();

  @$internal
  @override
  DiaryMealTimesController create() => DiaryMealTimesController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryMealTimes value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryMealTimes>(value),
    );
  }
}

String _$diaryMealTimesControllerHash() =>
    r'4267b7b5a323e6adeecc4fd0f3ecb1082df27fc3';

/// When the user's day starts and by when they eat each meal, saved on the
/// device.

abstract class _$DiaryMealTimesController extends $Notifier<DiaryMealTimes> {
  DiaryMealTimes build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DiaryMealTimes, DiaryMealTimes>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DiaryMealTimes, DiaryMealTimes>,
              DiaryMealTimes,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
