// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooked_meal_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Saves the "Gekocht" step of the meal [mealId].

@ProviderFor(CookedMealController)
final cookedMealControllerProvider = CookedMealControllerFamily._();

/// Saves the "Gekocht" step of the meal [mealId].
final class CookedMealControllerProvider
    extends $AsyncNotifierProvider<CookedMealController, void> {
  /// Saves the "Gekocht" step of the meal [mealId].
  CookedMealControllerProvider._({
    required CookedMealControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cookedMealControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cookedMealControllerHash();

  @override
  String toString() {
    return r'cookedMealControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CookedMealController create() => CookedMealController();

  @override
  bool operator ==(Object other) {
    return other is CookedMealControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cookedMealControllerHash() =>
    r'f38f2404ecd8c5d9ec678a196f7259190d85adf4';

/// Saves the "Gekocht" step of the meal [mealId].

final class CookedMealControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CookedMealController,
          AsyncValue<void>,
          void,
          FutureOr<void>,
          String
        > {
  CookedMealControllerFamily._()
    : super(
        retry: null,
        name: r'cookedMealControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Saves the "Gekocht" step of the meal [mealId].

  CookedMealControllerProvider call(String mealId) =>
      CookedMealControllerProvider._(argument: mealId, from: this);

  @override
  String toString() => r'cookedMealControllerProvider';
}

/// Saves the "Gekocht" step of the meal [mealId].

abstract class _$CookedMealController extends $AsyncNotifier<void> {
  late final _$args = ref.$arg as String;
  String get mealId => _$args;

  FutureOr<void> build(String mealId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
