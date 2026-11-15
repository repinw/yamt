// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_estimate_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Recipe estimate service.

@ProviderFor(recipeEstimateService)
final recipeEstimateServiceProvider = RecipeEstimateServiceProvider._();

/// Recipe estimate service.

final class RecipeEstimateServiceProvider
    extends
        $FunctionalProvider<
          RecipeEstimateService,
          RecipeEstimateService,
          RecipeEstimateService
        >
    with $Provider<RecipeEstimateService> {
  /// Recipe estimate service.
  RecipeEstimateServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeEstimateServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeEstimateServiceHash();

  @$internal
  @override
  $ProviderElement<RecipeEstimateService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecipeEstimateService create(Ref ref) {
    return recipeEstimateService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeEstimateService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeEstimateService>(value),
    );
  }
}

String _$recipeEstimateServiceHash() =>
    r'de19e71b1f45addbc49d4e5b0c024db09ed57094';

/// Recipe estimate runs.

@ProviderFor(recipeEstimateRuns)
final recipeEstimateRunsProvider = RecipeEstimateRunsProvider._();

/// Recipe estimate runs.

final class RecipeEstimateRunsProvider
    extends
        $FunctionalProvider<
          RecipeEstimateRuns,
          RecipeEstimateRuns,
          RecipeEstimateRuns
        >
    with $Provider<RecipeEstimateRuns> {
  /// Recipe estimate runs.
  RecipeEstimateRunsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeEstimateRunsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeEstimateRunsHash();

  @$internal
  @override
  $ProviderElement<RecipeEstimateRuns> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecipeEstimateRuns create(Ref ref) {
    return recipeEstimateRuns(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeEstimateRuns value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeEstimateRuns>(value),
    );
  }
}

String _$recipeEstimateRunsHash() =>
    r'69a30a8ebc9ba26f94e95987323a8dd8ef60cf7a';
