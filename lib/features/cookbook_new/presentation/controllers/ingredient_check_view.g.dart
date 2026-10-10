// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_check_view.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The recipe [recipeId] as the ingredient check shows it, or `null` when
/// the recipe is gone. It starts from the recipe page's portions and picks;
/// the check's own picks win, and the foods that "Hab ich" added are left
/// out.

@ProviderFor(ingredientCheckView)
final ingredientCheckViewProvider = IngredientCheckViewFamily._();

/// The recipe [recipeId] as the ingredient check shows it, or `null` when
/// the recipe is gone. It starts from the recipe page's portions and picks;
/// the check's own picks win, and the foods that "Hab ich" added are left
/// out.

final class IngredientCheckViewProvider
    extends
        $FunctionalProvider<
          AsyncValue<IngredientCheckView?>,
          AsyncValue<IngredientCheckView?>,
          AsyncValue<IngredientCheckView?>
        >
    with $Provider<AsyncValue<IngredientCheckView?>> {
  /// The recipe [recipeId] as the ingredient check shows it, or `null` when
  /// the recipe is gone. It starts from the recipe page's portions and picks;
  /// the check's own picks win, and the foods that "Hab ich" added are left
  /// out.
  IngredientCheckViewProvider._({
    required IngredientCheckViewFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'ingredientCheckViewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ingredientCheckViewHash();

  @override
  String toString() {
    return r'ingredientCheckViewProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<IngredientCheckView?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<IngredientCheckView?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return ingredientCheckView(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<IngredientCheckView?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<IngredientCheckView?>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IngredientCheckViewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ingredientCheckViewHash() =>
    r'09c4c160a72f2b350ab41c34a392eeee007d4216';

/// The recipe [recipeId] as the ingredient check shows it, or `null` when
/// the recipe is gone. It starts from the recipe page's portions and picks;
/// the check's own picks win, and the foods that "Hab ich" added are left
/// out.

final class IngredientCheckViewFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<IngredientCheckView?>,
          (String, String)
        > {
  IngredientCheckViewFamily._()
    : super(
        retry: null,
        name: r'ingredientCheckViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The recipe [recipeId] as the ingredient check shows it, or `null` when
  /// the recipe is gone. It starts from the recipe page's portions and picks;
  /// the check's own picks win, and the foods that "Hab ich" added are left
  /// out.

  IngredientCheckViewProvider call(String recipeId, String localeCode) =>
      IngredientCheckViewProvider._(
        argument: (recipeId, localeCode),
        from: this,
      );

  @override
  String toString() => r'ingredientCheckViewProvider';
}
