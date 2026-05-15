// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_food_serving_suggestion_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The global food serving suggestion repository provider.

@ProviderFor(globalFoodServingSuggestionRepository)
final globalFoodServingSuggestionRepositoryProvider =
    GlobalFoodServingSuggestionRepositoryProvider._();

/// The global food serving suggestion repository provider.

final class GlobalFoodServingSuggestionRepositoryProvider
    extends
        $FunctionalProvider<
          GlobalFoodServingSuggestionRepository,
          GlobalFoodServingSuggestionRepository,
          GlobalFoodServingSuggestionRepository
        >
    with $Provider<GlobalFoodServingSuggestionRepository> {
  /// The global food serving suggestion repository provider.
  GlobalFoodServingSuggestionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalFoodServingSuggestionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$globalFoodServingSuggestionRepositoryHash();

  @$internal
  @override
  $ProviderElement<GlobalFoodServingSuggestionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GlobalFoodServingSuggestionRepository create(Ref ref) {
    return globalFoodServingSuggestionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobalFoodServingSuggestionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<GlobalFoodServingSuggestionRepository>(value),
    );
  }
}

String _$globalFoodServingSuggestionRepositoryHash() =>
    r'b3808d89676bf546f7bb4f9f9f310762066295c2';
