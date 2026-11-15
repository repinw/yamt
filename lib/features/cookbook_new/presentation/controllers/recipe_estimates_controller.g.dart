// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_estimates_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Estimates every saved recipe of the Kochbuch whose estimate does not fit
/// its lines, at most [_maxRunning] at once, and holds the ids of the recipes
/// running or waiting for their turn, so their cards can show that a value
/// is coming.
///
/// Each recipe is tried once while this controller lives, which in the home
/// shell is until the next app start; a failure leaves it without an
/// estimate. Only opening its recipe page tries again, and not when the AI's
/// answer could not be used.

@ProviderFor(RecipeEstimatesController)
final recipeEstimatesControllerProvider = RecipeEstimatesControllerProvider._();

/// Estimates every saved recipe of the Kochbuch whose estimate does not fit
/// its lines, at most [_maxRunning] at once, and holds the ids of the recipes
/// running or waiting for their turn, so their cards can show that a value
/// is coming.
///
/// Each recipe is tried once while this controller lives, which in the home
/// shell is until the next app start; a failure leaves it without an
/// estimate. Only opening its recipe page tries again, and not when the AI's
/// answer could not be used.
final class RecipeEstimatesControllerProvider
    extends $NotifierProvider<RecipeEstimatesController, Set<String>> {
  /// Estimates every saved recipe of the Kochbuch whose estimate does not fit
  /// its lines, at most [_maxRunning] at once, and holds the ids of the recipes
  /// running or waiting for their turn, so their cards can show that a value
  /// is coming.
  ///
  /// Each recipe is tried once while this controller lives, which in the home
  /// shell is until the next app start; a failure leaves it without an
  /// estimate. Only opening its recipe page tries again, and not when the AI's
  /// answer could not be used.
  RecipeEstimatesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeEstimatesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeEstimatesControllerHash();

  @$internal
  @override
  RecipeEstimatesController create() => RecipeEstimatesController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$recipeEstimatesControllerHash() =>
    r'cfe0e8d70d7a492aa8fd18a60d1fe8dacbc2bb85';

/// Estimates every saved recipe of the Kochbuch whose estimate does not fit
/// its lines, at most [_maxRunning] at once, and holds the ids of the recipes
/// running or waiting for their turn, so their cards can show that a value
/// is coming.
///
/// Each recipe is tried once while this controller lives, which in the home
/// shell is until the next app start; a failure leaves it without an
/// estimate. Only opening its recipe page tries again, and not when the AI's
/// answer could not be used.

abstract class _$RecipeEstimatesController extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
