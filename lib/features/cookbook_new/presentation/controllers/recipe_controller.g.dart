// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the portions and Vorrat picks of the recipe [recipeId] and cooks it.

@ProviderFor(RecipeController)
final recipeControllerProvider = RecipeControllerFamily._();

/// Holds the portions and Vorrat picks of the recipe [recipeId] and cooks it.
final class RecipeControllerProvider
    extends $NotifierProvider<RecipeController, RecipeDraft> {
  /// Holds the portions and Vorrat picks of the recipe [recipeId] and cooks it.
  RecipeControllerProvider._({
    required RecipeControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recipeControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeControllerHash();

  @override
  String toString() {
    return r'recipeControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RecipeController create() => RecipeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeDraft>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeControllerHash() => r'31ee2c4d5c1ffe1aebb2373a967851f79600cb46';

/// Holds the portions and Vorrat picks of the recipe [recipeId] and cooks it.

final class RecipeControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          RecipeController,
          RecipeDraft,
          RecipeDraft,
          RecipeDraft,
          String
        > {
  RecipeControllerFamily._()
    : super(
        retry: null,
        name: r'recipeControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Holds the portions and Vorrat picks of the recipe [recipeId] and cooks it.

  RecipeControllerProvider call(String recipeId) =>
      RecipeControllerProvider._(argument: recipeId, from: this);

  @override
  String toString() => r'recipeControllerProvider';
}

/// Holds the portions and Vorrat picks of the recipe [recipeId] and cooks it.

abstract class _$RecipeController extends $Notifier<RecipeDraft> {
  late final _$args = ref.$arg as String;
  String get recipeId => _$args;

  RecipeDraft build(String recipeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RecipeDraft, RecipeDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RecipeDraft, RecipeDraft>,
              RecipeDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// The recipe [recipeId] with its ingredients for the chosen portions and
/// their Vorrat items, or `null` when the recipe is gone; see
/// [buildRecipeView].

@ProviderFor(recipeView)
final recipeViewProvider = RecipeViewFamily._();

/// The recipe [recipeId] with its ingredients for the chosen portions and
/// their Vorrat items, or `null` when the recipe is gone; see
/// [buildRecipeView].

final class RecipeViewProvider
    extends
        $FunctionalProvider<
          AsyncValue<RecipeView?>,
          AsyncValue<RecipeView?>,
          AsyncValue<RecipeView?>
        >
    with $Provider<AsyncValue<RecipeView?>> {
  /// The recipe [recipeId] with its ingredients for the chosen portions and
  /// their Vorrat items, or `null` when the recipe is gone; see
  /// [buildRecipeView].
  RecipeViewProvider._({
    required RecipeViewFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'recipeViewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeViewHash();

  @override
  String toString() {
    return r'recipeViewProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<RecipeView?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<RecipeView?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return recipeView(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<RecipeView?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<RecipeView?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeViewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeViewHash() => r'4368e02388c6b209c1a4d2795a5730a50320a198';

/// The recipe [recipeId] with its ingredients for the chosen portions and
/// their Vorrat items, or `null` when the recipe is gone; see
/// [buildRecipeView].

final class RecipeViewFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<RecipeView?>, (String, String)> {
  RecipeViewFamily._()
    : super(
        retry: null,
        name: r'recipeViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The recipe [recipeId] with its ingredients for the chosen portions and
  /// their Vorrat items, or `null` when the recipe is gone; see
  /// [buildRecipeView].

  RecipeViewProvider call(String recipeId, String localeCode) =>
      RecipeViewProvider._(argument: (recipeId, localeCode), from: this);

  @override
  String toString() => r'recipeViewProvider';
}
