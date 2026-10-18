// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_check_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the choices of the ingredient check for one recipe and saves them
/// on the recipe.

@ProviderFor(IngredientCheckController)
final ingredientCheckControllerProvider = IngredientCheckControllerFamily._();

/// Holds the choices of the ingredient check for one recipe and saves them
/// on the recipe.
final class IngredientCheckControllerProvider
    extends $NotifierProvider<IngredientCheckController, IngredientCheckState> {
  /// Holds the choices of the ingredient check for one recipe and saves them
  /// on the recipe.
  IngredientCheckControllerProvider._({
    required IngredientCheckControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ingredientCheckControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ingredientCheckControllerHash();

  @override
  String toString() {
    return r'ingredientCheckControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  IngredientCheckController create() => IngredientCheckController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IngredientCheckState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IngredientCheckState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IngredientCheckControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ingredientCheckControllerHash() =>
    r'49631aa6d00093dede98b9fd7881a80827e15c4f';

/// Holds the choices of the ingredient check for one recipe and saves them
/// on the recipe.

final class IngredientCheckControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          IngredientCheckController,
          IngredientCheckState,
          IngredientCheckState,
          IngredientCheckState,
          String
        > {
  IngredientCheckControllerFamily._()
    : super(
        retry: null,
        name: r'ingredientCheckControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Holds the choices of the ingredient check for one recipe and saves them
  /// on the recipe.

  IngredientCheckControllerProvider call(String recipeId) =>
      IngredientCheckControllerProvider._(argument: recipeId, from: this);

  @override
  String toString() => r'ingredientCheckControllerProvider';
}

/// Holds the choices of the ingredient check for one recipe and saves them
/// on the recipe.

abstract class _$IngredientCheckController
    extends $Notifier<IngredientCheckState> {
  late final _$args = ref.$arg as String;
  String get recipeId => _$args;

  IngredientCheckState build(String recipeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<IngredientCheckState, IngredientCheckState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<IngredientCheckState, IngredientCheckState>,
              IngredientCheckState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
