// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_idea_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The picture of the recipe [idea], which comes after its text, and saving
/// the idea to the Kochbuch.
///
/// A picture that fails is not asked for again: every try is a paid call,
/// and the recipe is fine without one. Its generator depends on nothing that
/// changes, so the picture is asked for once per idea.

@ProviderFor(RecipeIdeaController)
final recipeIdeaControllerProvider = RecipeIdeaControllerFamily._();

/// The picture of the recipe [idea], which comes after its text, and saving
/// the idea to the Kochbuch.
///
/// A picture that fails is not asked for again: every try is a paid call,
/// and the recipe is fine without one. Its generator depends on nothing that
/// changes, so the picture is asked for once per idea.
final class RecipeIdeaControllerProvider
    extends $AsyncNotifierProvider<RecipeIdeaController, Uint8List> {
  /// The picture of the recipe [idea], which comes after its text, and saving
  /// the idea to the Kochbuch.
  ///
  /// A picture that fails is not asked for again: every try is a paid call,
  /// and the recipe is fine without one. Its generator depends on nothing that
  /// changes, so the picture is asked for once per idea.
  RecipeIdeaControllerProvider._({
    required RecipeIdeaControllerFamily super.from,
    required AiChefRecipeIdea super.argument,
  }) : super(
         retry: _noRetry,
         name: r'recipeIdeaControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeIdeaControllerHash();

  @override
  String toString() {
    return r'recipeIdeaControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RecipeIdeaController create() => RecipeIdeaController();

  @override
  bool operator ==(Object other) {
    return other is RecipeIdeaControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeIdeaControllerHash() =>
    r'9fdacd98924dc8f9e811d45276d9f37a6c209ee6';

/// The picture of the recipe [idea], which comes after its text, and saving
/// the idea to the Kochbuch.
///
/// A picture that fails is not asked for again: every try is a paid call,
/// and the recipe is fine without one. Its generator depends on nothing that
/// changes, so the picture is asked for once per idea.

final class RecipeIdeaControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          RecipeIdeaController,
          AsyncValue<Uint8List>,
          Uint8List,
          FutureOr<Uint8List>,
          AiChefRecipeIdea
        > {
  RecipeIdeaControllerFamily._()
    : super(
        retry: _noRetry,
        name: r'recipeIdeaControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The picture of the recipe [idea], which comes after its text, and saving
  /// the idea to the Kochbuch.
  ///
  /// A picture that fails is not asked for again: every try is a paid call,
  /// and the recipe is fine without one. Its generator depends on nothing that
  /// changes, so the picture is asked for once per idea.

  RecipeIdeaControllerProvider call(AiChefRecipeIdea idea) =>
      RecipeIdeaControllerProvider._(argument: idea, from: this);

  @override
  String toString() => r'recipeIdeaControllerProvider';
}

/// The picture of the recipe [idea], which comes after its text, and saving
/// the idea to the Kochbuch.
///
/// A picture that fails is not asked for again: every try is a paid call,
/// and the recipe is fine without one. Its generator depends on nothing that
/// changes, so the picture is asked for once per idea.

abstract class _$RecipeIdeaController extends $AsyncNotifier<Uint8List> {
  late final _$args = ref.$arg as AiChefRecipeIdea;
  AiChefRecipeIdea get idea => _$args;

  FutureOr<Uint8List> build(AiChefRecipeIdea idea);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Uint8List>, Uint8List>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Uint8List>, Uint8List>,
              AsyncValue<Uint8List>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// The recipe of [idea] as the recipe page shows it, for its own portions,
/// with the Vorrat items of each ingredient ([buildRecipeView]). The Vorrat
/// adds its items when it is there; the recipe never waits for it.

@ProviderFor(recipeIdeaView)
final recipeIdeaViewProvider = RecipeIdeaViewFamily._();

/// The recipe of [idea] as the recipe page shows it, for its own portions,
/// with the Vorrat items of each ingredient ([buildRecipeView]). The Vorrat
/// adds its items when it is there; the recipe never waits for it.

final class RecipeIdeaViewProvider
    extends $FunctionalProvider<RecipeView, RecipeView, RecipeView>
    with $Provider<RecipeView> {
  /// The recipe of [idea] as the recipe page shows it, for its own portions,
  /// with the Vorrat items of each ingredient ([buildRecipeView]). The Vorrat
  /// adds its items when it is there; the recipe never waits for it.
  RecipeIdeaViewProvider._({
    required RecipeIdeaViewFamily super.from,
    required (AiChefRecipeIdea, String) super.argument,
  }) : super(
         retry: null,
         name: r'recipeIdeaViewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeIdeaViewHash();

  @override
  String toString() {
    return r'recipeIdeaViewProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<RecipeView> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecipeView create(Ref ref) {
    final argument = this.argument as (AiChefRecipeIdea, String);
    return recipeIdeaView(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeView value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeView>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeIdeaViewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeIdeaViewHash() => r'1923157f956af2db966ff31f8f8f5df2172ea634';

/// The recipe of [idea] as the recipe page shows it, for its own portions,
/// with the Vorrat items of each ingredient ([buildRecipeView]). The Vorrat
/// adds its items when it is there; the recipe never waits for it.

final class RecipeIdeaViewFamily extends $Family
    with $FunctionalFamilyOverride<RecipeView, (AiChefRecipeIdea, String)> {
  RecipeIdeaViewFamily._()
    : super(
        retry: null,
        name: r'recipeIdeaViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The recipe of [idea] as the recipe page shows it, for its own portions,
  /// with the Vorrat items of each ingredient ([buildRecipeView]). The Vorrat
  /// adds its items when it is there; the recipe never waits for it.

  RecipeIdeaViewProvider call(AiChefRecipeIdea idea, String localeCode) =>
      RecipeIdeaViewProvider._(argument: (idea, localeCode), from: this);

  @override
  String toString() => r'recipeIdeaViewProvider';
}
