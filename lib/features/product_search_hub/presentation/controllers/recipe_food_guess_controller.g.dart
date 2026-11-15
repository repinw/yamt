// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_food_guess_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Estimates a food by its name for a recipe line whose cook does not want
/// to pick one ("Egal, irgendeins"). The state is loading while the AI
/// works and holds the error of a failed estimate.

@ProviderFor(RecipeFoodGuessController)
final recipeFoodGuessControllerProvider = RecipeFoodGuessControllerProvider._();

/// Estimates a food by its name for a recipe line whose cook does not want
/// to pick one ("Egal, irgendeins"). The state is loading while the AI
/// works and holds the error of a failed estimate.
final class RecipeFoodGuessControllerProvider
    extends $NotifierProvider<RecipeFoodGuessController, AsyncValue<void>> {
  /// Estimates a food by its name for a recipe line whose cook does not want
  /// to pick one ("Egal, irgendeins"). The state is loading while the AI
  /// works and holds the error of a failed estimate.
  RecipeFoodGuessControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeFoodGuessControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeFoodGuessControllerHash();

  @$internal
  @override
  RecipeFoodGuessController create() => RecipeFoodGuessController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$recipeFoodGuessControllerHash() =>
    r'cc5b73f14ba0d7fe71542f91dd5df459a40953f4';

/// Estimates a food by its name for a recipe line whose cook does not want
/// to pick one ("Egal, irgendeins"). The state is loading while the AI
/// works and holds the error of a failed estimate.

abstract class _$RecipeFoodGuessController extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
