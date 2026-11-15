// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_estimate_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Recipe estimate template client.

@ProviderFor(recipeEstimateTemplateClient)
final recipeEstimateTemplateClientProvider =
    RecipeEstimateTemplateClientProvider._();

/// Recipe estimate template client.

final class RecipeEstimateTemplateClientProvider
    extends
        $FunctionalProvider<
          RecipeEstimateTemplateClient,
          RecipeEstimateTemplateClient,
          RecipeEstimateTemplateClient
        >
    with $Provider<RecipeEstimateTemplateClient> {
  /// Recipe estimate template client.
  RecipeEstimateTemplateClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeEstimateTemplateClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeEstimateTemplateClientHash();

  @$internal
  @override
  $ProviderElement<RecipeEstimateTemplateClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecipeEstimateTemplateClient create(Ref ref) {
    return recipeEstimateTemplateClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeEstimateTemplateClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeEstimateTemplateClient>(value),
    );
  }
}

String _$recipeEstimateTemplateClientHash() =>
    r'880431d869ef1339bbe0bc66e675b17e50b58ea1';

/// Recipe estimate repository.

@ProviderFor(recipeEstimateRepository)
final recipeEstimateRepositoryProvider = RecipeEstimateRepositoryProvider._();

/// Recipe estimate repository.

final class RecipeEstimateRepositoryProvider
    extends
        $FunctionalProvider<
          RecipeEstimateRepository,
          RecipeEstimateRepository,
          RecipeEstimateRepository
        >
    with $Provider<RecipeEstimateRepository> {
  /// Recipe estimate repository.
  RecipeEstimateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeEstimateRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeEstimateRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecipeEstimateRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecipeEstimateRepository create(Ref ref) {
    return recipeEstimateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeEstimateRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeEstimateRepository>(value),
    );
  }
}

String _$recipeEstimateRepositoryHash() =>
    r'a455b6ec0da59e5ee498bf49d465f1f2570e63d1';
