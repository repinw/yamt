// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_line_states.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The state of each ingredient line of the recipe [recipeId] by its index
/// in the saved ingredients when the cook run started, or `null` without a
/// cook run. Lines the cook run added itself do not count.

@ProviderFor(recipeLineStates)
final recipeLineStatesProvider = RecipeLineStatesFamily._();

/// The state of each ingredient line of the recipe [recipeId] by its index
/// in the saved ingredients when the cook run started, or `null` without a
/// cook run. Lines the cook run added itself do not count.

final class RecipeLineStatesProvider
    extends
        $FunctionalProvider<
          Map<int, RecipeLineState>?,
          Map<int, RecipeLineState>?,
          Map<int, RecipeLineState>?
        >
    with $Provider<Map<int, RecipeLineState>?> {
  /// The state of each ingredient line of the recipe [recipeId] by its index
  /// in the saved ingredients when the cook run started, or `null` without a
  /// cook run. Lines the cook run added itself do not count.
  RecipeLineStatesProvider._({
    required RecipeLineStatesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recipeLineStatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeLineStatesHash();

  @override
  String toString() {
    return r'recipeLineStatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Map<int, RecipeLineState>?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<int, RecipeLineState>? create(Ref ref) {
    final argument = this.argument as String;
    return recipeLineStates(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<int, RecipeLineState>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<int, RecipeLineState>?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeLineStatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeLineStatesHash() => r'248605d9261fe654fa4a98f6ba57cdcdfaaf3ef0';

/// The state of each ingredient line of the recipe [recipeId] by its index
/// in the saved ingredients when the cook run started, or `null` without a
/// cook run. Lines the cook run added itself do not count.

final class RecipeLineStatesFamily extends $Family
    with $FunctionalFamilyOverride<Map<int, RecipeLineState>?, String> {
  RecipeLineStatesFamily._()
    : super(
        retry: null,
        name: r'recipeLineStatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The state of each ingredient line of the recipe [recipeId] by its index
  /// in the saved ingredients when the cook run started, or `null` without a
  /// cook run. Lines the cook run added itself do not count.

  RecipeLineStatesProvider call(String recipeId) =>
      RecipeLineStatesProvider._(argument: recipeId, from: this);

  @override
  String toString() => r'recipeLineStatesProvider';
}
