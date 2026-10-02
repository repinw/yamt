// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooked_meal_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Vorrat meal [mealId], or `null` when it is gone.

@ProviderFor(cookedMeal)
final cookedMealProvider = CookedMealFamily._();

/// The Vorrat meal [mealId], or `null` when it is gone.

final class CookedMealProvider
    extends
        $FunctionalProvider<
          AsyncValue<PreparedMeal?>,
          AsyncValue<PreparedMeal?>,
          AsyncValue<PreparedMeal?>
        >
    with $Provider<AsyncValue<PreparedMeal?>> {
  /// The Vorrat meal [mealId], or `null` when it is gone.
  CookedMealProvider._({
    required CookedMealFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cookedMealProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cookedMealHash();

  @override
  String toString() {
    return r'cookedMealProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<PreparedMeal?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<PreparedMeal?> create(Ref ref) {
    final argument = this.argument as String;
    return cookedMeal(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<PreparedMeal?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<PreparedMeal?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CookedMealProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cookedMealHash() => r'ab42cf1108a1fb431636819b1374b82cdbfdb5ce';

/// The Vorrat meal [mealId], or `null` when it is gone.

final class CookedMealFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<PreparedMeal?>, String> {
  CookedMealFamily._()
    : super(
        retry: null,
        name: r'cookedMealProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The Vorrat meal [mealId], or `null` when it is gone.

  CookedMealProvider call(String mealId) =>
      CookedMealProvider._(argument: mealId, from: this);

  @override
  String toString() => r'cookedMealProvider';
}

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
    r'54b89feb9f645c365d76bd7b37304ec0fe798160';

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
