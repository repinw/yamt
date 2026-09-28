// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_entries_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Defines calorie entries controller.

@ProviderFor(CalorieEntriesController)
final calorieEntriesControllerProvider = CalorieEntriesControllerProvider._();

/// Defines calorie entries controller.
final class CalorieEntriesControllerProvider
    extends
        $AsyncNotifierProvider<CalorieEntriesController, List<CalorieEntry>> {
  /// Defines calorie entries controller.
  CalorieEntriesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieEntriesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieEntriesControllerHash();

  @$internal
  @override
  CalorieEntriesController create() => CalorieEntriesController();
}

String _$calorieEntriesControllerHash() =>
    r'0a1d53e597d05b5d0b6fc08176ac62c55155845c';

/// Defines calorie entries controller.

abstract class _$CalorieEntriesController
    extends $AsyncNotifier<List<CalorieEntry>> {
  FutureOr<List<CalorieEntry>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<CalorieEntry>>, List<CalorieEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CalorieEntry>>, List<CalorieEntry>>,
              AsyncValue<List<CalorieEntry>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Calorie day view data.

@ProviderFor(calorieDayViewData)
final calorieDayViewDataProvider = CalorieDayViewDataProvider._();

/// Calorie day view data.

final class CalorieDayViewDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieDayViewData>,
          AsyncValue<CalorieDayViewData>,
          AsyncValue<CalorieDayViewData>
        >
    with $Provider<AsyncValue<CalorieDayViewData>> {
  /// Calorie day view data.
  CalorieDayViewDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieDayViewDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieDayViewDataHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<CalorieDayViewData>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<CalorieDayViewData> create(Ref ref) {
    return calorieDayViewData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<CalorieDayViewData> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<CalorieDayViewData>>(
        value,
      ),
    );
  }
}

String _$calorieDayViewDataHash() =>
    r'52ee495a1d49327e32ac9e5c9d5d228c6912c6da';
