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
    r'1a0f172352c7501efc8d6cbb9813e4840ee0ab8b';

/// Defines calorie entries controller.

abstract class _$CalorieEntriesController
    extends $AsyncNotifier<List<CalorieEntry>> {
  FutureOr<List<CalorieEntry>> build();
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, build);
  }
}

/// Calorie entry by id.

@ProviderFor(calorieEntryById)
final calorieEntryByIdProvider = CalorieEntryByIdFamily._();

/// Calorie entry by id.

final class CalorieEntryByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieEntry?>,
          CalorieEntry?,
          FutureOr<CalorieEntry?>
        >
    with $FutureModifier<CalorieEntry?>, $FutureProvider<CalorieEntry?> {
  /// Calorie entry by id.
  CalorieEntryByIdProvider._({
    required CalorieEntryByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'calorieEntryByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calorieEntryByIdHash();

  @override
  String toString() {
    return r'calorieEntryByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CalorieEntry?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieEntry?> create(Ref ref) {
    final argument = this.argument as String;
    return calorieEntryById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CalorieEntryByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calorieEntryByIdHash() => r'5a59a396ab6e1f6b79c6f084214ccffb13846fcb';

/// Calorie entry by id.

final class CalorieEntryByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CalorieEntry?>, String> {
  CalorieEntryByIdFamily._()
    : super(
        retry: null,
        name: r'calorieEntryByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Calorie entry by id.

  CalorieEntryByIdProvider call(String entryId) =>
      CalorieEntryByIdProvider._(argument: entryId, from: this);

  @override
  String toString() => r'calorieEntryByIdProvider';
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
