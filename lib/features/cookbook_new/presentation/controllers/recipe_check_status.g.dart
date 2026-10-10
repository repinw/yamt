// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_check_status.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The ingredients of the recipe [recipeId] that are missing or only partly
/// there and whose shopping text is not on the shopping list yet.

@ProviderFor(recipeCheckStatus)
final recipeCheckStatusProvider = RecipeCheckStatusFamily._();

/// The ingredients of the recipe [recipeId] that are missing or only partly
/// there and whose shopping text is not on the shopping list yet.

final class RecipeCheckStatusProvider
    extends
        $FunctionalProvider<
          RecipeCheckStatus,
          RecipeCheckStatus,
          RecipeCheckStatus
        >
    with $Provider<RecipeCheckStatus> {
  /// The ingredients of the recipe [recipeId] that are missing or only partly
  /// there and whose shopping text is not on the shopping list yet.
  RecipeCheckStatusProvider._({
    required RecipeCheckStatusFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'recipeCheckStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeCheckStatusHash();

  @override
  String toString() {
    return r'recipeCheckStatusProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<RecipeCheckStatus> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecipeCheckStatus create(Ref ref) {
    final argument = this.argument as (String, String);
    return recipeCheckStatus(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeCheckStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeCheckStatus>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeCheckStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeCheckStatusHash() => r'ccc1177be5337b79c3fe50c9ac45852b153a7ef4';

/// The ingredients of the recipe [recipeId] that are missing or only partly
/// there and whose shopping text is not on the shopping list yet.

final class RecipeCheckStatusFamily extends $Family
    with $FunctionalFamilyOverride<RecipeCheckStatus, (String, String)> {
  RecipeCheckStatusFamily._()
    : super(
        retry: null,
        name: r'recipeCheckStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The ingredients of the recipe [recipeId] that are missing or only partly
  /// there and whose shopping text is not on the shopping list yet.

  RecipeCheckStatusProvider call(String recipeId, String localeCode) =>
      RecipeCheckStatusProvider._(argument: (recipeId, localeCode), from: this);

  @override
  String toString() => r'recipeCheckStatusProvider';
}
