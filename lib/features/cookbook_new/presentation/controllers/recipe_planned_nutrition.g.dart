// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_planned_nutrition.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One portion of the recipe [recipeId], the one place every screen reads
/// it from. Before cooking, the AI's estimate. While cooking, each line
/// planned from the Vorrat brings its real values instead of its estimate;
/// once no line is open or waits on the shopping list, the portion holds
/// only real values and is no longer `estimated`. `null` without an
/// estimate while a line still needs one.

@ProviderFor(recipePortion)
final recipePortionProvider = RecipePortionFamily._();

/// One portion of the recipe [recipeId], the one place every screen reads
/// it from. Before cooking, the AI's estimate. While cooking, each line
/// planned from the Vorrat brings its real values instead of its estimate;
/// once no line is open or waits on the shopping list, the portion holds
/// only real values and is no longer `estimated`. `null` without an
/// estimate while a line still needs one.

final class RecipePortionProvider
    extends $FunctionalProvider<RecipePortion?, RecipePortion?, RecipePortion?>
    with $Provider<RecipePortion?> {
  /// One portion of the recipe [recipeId], the one place every screen reads
  /// it from. Before cooking, the AI's estimate. While cooking, each line
  /// planned from the Vorrat brings its real values instead of its estimate;
  /// once no line is open or waits on the shopping list, the portion holds
  /// only real values and is no longer `estimated`. `null` without an
  /// estimate while a line still needs one.
  RecipePortionProvider._({
    required RecipePortionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recipePortionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipePortionHash();

  @override
  String toString() {
    return r'recipePortionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<RecipePortion?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecipePortion? create(Ref ref) {
    final argument = this.argument as String;
    return recipePortion(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipePortion? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipePortion?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecipePortionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipePortionHash() => r'59e11165e851a658d99cf8a7431f0c65e7053d00';

/// One portion of the recipe [recipeId], the one place every screen reads
/// it from. Before cooking, the AI's estimate. While cooking, each line
/// planned from the Vorrat brings its real values instead of its estimate;
/// once no line is open or waits on the shopping list, the portion holds
/// only real values and is no longer `estimated`. `null` without an
/// estimate while a line still needs one.

final class RecipePortionFamily extends $Family
    with $FunctionalFamilyOverride<RecipePortion?, String> {
  RecipePortionFamily._()
    : super(
        retry: null,
        name: r'recipePortionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One portion of the recipe [recipeId], the one place every screen reads
  /// it from. Before cooking, the AI's estimate. While cooking, each line
  /// planned from the Vorrat brings its real values instead of its estimate;
  /// once no line is open or waits on the shopping list, the portion holds
  /// only real values and is no longer `estimated`. `null` without an
  /// estimate while a line still needs one.

  RecipePortionProvider call(String recipeId) =>
      RecipePortionProvider._(argument: recipeId, from: this);

  @override
  String toString() => r'recipePortionProvider';
}
