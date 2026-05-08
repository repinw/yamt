// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_calculator_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Defines calorie goal calculator form controller.

@ProviderFor(CalorieGoalCalculatorFormController)
final calorieGoalCalculatorFormControllerProvider =
    CalorieGoalCalculatorFormControllerFamily._();

/// Defines calorie goal calculator form controller.
final class CalorieGoalCalculatorFormControllerProvider
    extends
        $NotifierProvider<
          CalorieGoalCalculatorFormController,
          CalorieGoalCalculatorFormState
        > {
  /// Defines calorie goal calculator form controller.
  CalorieGoalCalculatorFormControllerProvider._({
    required CalorieGoalCalculatorFormControllerFamily super.from,
    required (CalorieCalculatorProfile?, {bool useEmptyDefaults})
    super.argument,
  }) : super(
         retry: null,
         name: r'calorieGoalCalculatorFormControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$calorieGoalCalculatorFormControllerHash();

  @override
  String toString() {
    return r'calorieGoalCalculatorFormControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  CalorieGoalCalculatorFormController create() =>
      CalorieGoalCalculatorFormController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieGoalCalculatorFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieGoalCalculatorFormState>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CalorieGoalCalculatorFormControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calorieGoalCalculatorFormControllerHash() =>
    r'1ecb935b552a14e814169a9b821a109a25f25fcd';

/// Defines calorie goal calculator form controller.

final class CalorieGoalCalculatorFormControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CalorieGoalCalculatorFormController,
          CalorieGoalCalculatorFormState,
          CalorieGoalCalculatorFormState,
          CalorieGoalCalculatorFormState,
          (CalorieCalculatorProfile?, {bool useEmptyDefaults})
        > {
  CalorieGoalCalculatorFormControllerFamily._()
    : super(
        retry: null,
        name: r'calorieGoalCalculatorFormControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Defines calorie goal calculator form controller.

  CalorieGoalCalculatorFormControllerProvider call(
    CalorieCalculatorProfile? initialProfile, {
    bool useEmptyDefaults = false,
  }) => CalorieGoalCalculatorFormControllerProvider._(
    argument: (initialProfile, useEmptyDefaults: useEmptyDefaults),
    from: this,
  );

  @override
  String toString() => r'calorieGoalCalculatorFormControllerProvider';
}

/// Defines calorie goal calculator form controller.

abstract class _$CalorieGoalCalculatorFormController
    extends $Notifier<CalorieGoalCalculatorFormState> {
  late final _$args =
      ref.$arg as (CalorieCalculatorProfile?, {bool useEmptyDefaults});
  CalorieCalculatorProfile? get initialProfile => _$args.$1;
  bool get useEmptyDefaults => _$args.useEmptyDefaults;

  CalorieGoalCalculatorFormState build(
    CalorieCalculatorProfile? initialProfile, {
    bool useEmptyDefaults = false,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              CalorieGoalCalculatorFormState,
              CalorieGoalCalculatorFormState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                CalorieGoalCalculatorFormState,
                CalorieGoalCalculatorFormState
              >,
              CalorieGoalCalculatorFormState,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(_$args.$1, useEmptyDefaults: _$args.useEmptyDefaults),
    );
  }
}
