// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_editor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the state of the open editor [editorId]: a new recipe when
/// [recipeId] is `null`, else the saved recipe [recipeId]. The state is
/// `null` when that recipe is gone.
///
/// Every editor of a new recipe has its own [editorId], so two of them never
/// share a draft; the editor of a saved recipe uses the recipe's id.

@ProviderFor(RecipeEditorController)
final recipeEditorControllerProvider = RecipeEditorControllerFamily._();

/// Holds the state of the open editor [editorId]: a new recipe when
/// [recipeId] is `null`, else the saved recipe [recipeId]. The state is
/// `null` when that recipe is gone.
///
/// Every editor of a new recipe has its own [editorId], so two of them never
/// share a draft; the editor of a saved recipe uses the recipe's id.
final class RecipeEditorControllerProvider
    extends $AsyncNotifierProvider<RecipeEditorController, RecipeEditorState?> {
  /// Holds the state of the open editor [editorId]: a new recipe when
  /// [recipeId] is `null`, else the saved recipe [recipeId]. The state is
  /// `null` when that recipe is gone.
  ///
  /// Every editor of a new recipe has its own [editorId], so two of them never
  /// share a draft; the editor of a saved recipe uses the recipe's id.
  RecipeEditorControllerProvider._({
    required RecipeEditorControllerFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'recipeEditorControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeEditorControllerHash();

  @override
  String toString() {
    return r'recipeEditorControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  RecipeEditorController create() => RecipeEditorController();

  @override
  bool operator ==(Object other) {
    return other is RecipeEditorControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeEditorControllerHash() =>
    r'd8ff1859c2c5e3268a74f7c32f9241e9cf7d9ed2';

/// Holds the state of the open editor [editorId]: a new recipe when
/// [recipeId] is `null`, else the saved recipe [recipeId]. The state is
/// `null` when that recipe is gone.
///
/// Every editor of a new recipe has its own [editorId], so two of them never
/// share a draft; the editor of a saved recipe uses the recipe's id.

final class RecipeEditorControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          RecipeEditorController,
          AsyncValue<RecipeEditorState?>,
          RecipeEditorState?,
          FutureOr<RecipeEditorState?>,
          (String, String?)
        > {
  RecipeEditorControllerFamily._()
    : super(
        retry: null,
        name: r'recipeEditorControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Holds the state of the open editor [editorId]: a new recipe when
  /// [recipeId] is `null`, else the saved recipe [recipeId]. The state is
  /// `null` when that recipe is gone.
  ///
  /// Every editor of a new recipe has its own [editorId], so two of them never
  /// share a draft; the editor of a saved recipe uses the recipe's id.

  RecipeEditorControllerProvider call(String editorId, String? recipeId) =>
      RecipeEditorControllerProvider._(
        argument: (editorId, recipeId),
        from: this,
      );

  @override
  String toString() => r'recipeEditorControllerProvider';
}

/// Holds the state of the open editor [editorId]: a new recipe when
/// [recipeId] is `null`, else the saved recipe [recipeId]. The state is
/// `null` when that recipe is gone.
///
/// Every editor of a new recipe has its own [editorId], so two of them never
/// share a draft; the editor of a saved recipe uses the recipe's id.

abstract class _$RecipeEditorController
    extends $AsyncNotifier<RecipeEditorState?> {
  late final _$args = ref.$arg as (String, String?);
  String get editorId => _$args.$1;
  String? get recipeId => _$args.$2;

  FutureOr<RecipeEditorState?> build(String editorId, String? recipeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<RecipeEditorState?>, RecipeEditorState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<RecipeEditorState?>, RecipeEditorState?>,
              AsyncValue<RecipeEditorState?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
