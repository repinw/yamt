// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_check_save_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The workflow on the household's cookbook and shopping list.

@ProviderFor(ingredientCheckSaveService)
final ingredientCheckSaveServiceProvider =
    IngredientCheckSaveServiceProvider._();

/// The workflow on the household's cookbook and shopping list.

final class IngredientCheckSaveServiceProvider
    extends
        $FunctionalProvider<
          IngredientCheckSaveService,
          IngredientCheckSaveService,
          IngredientCheckSaveService
        >
    with $Provider<IngredientCheckSaveService> {
  /// The workflow on the household's cookbook and shopping list.
  IngredientCheckSaveServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ingredientCheckSaveServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ingredientCheckSaveServiceHash();

  @$internal
  @override
  $ProviderElement<IngredientCheckSaveService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IngredientCheckSaveService create(Ref ref) {
    return ingredientCheckSaveService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IngredientCheckSaveService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IngredientCheckSaveService>(value),
    );
  }
}

String _$ingredientCheckSaveServiceHash() =>
    r'1b9c85c596b4774bf45f918d63c6da1cf0f6ca71';
