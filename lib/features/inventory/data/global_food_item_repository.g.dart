// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_food_item_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Global food item repository.

@ProviderFor(globalFoodItemRepository)
final globalFoodItemRepositoryProvider = GlobalFoodItemRepositoryProvider._();

/// Global food item repository.

final class GlobalFoodItemRepositoryProvider
    extends
        $FunctionalProvider<
          GlobalFoodItemRepository,
          GlobalFoodItemRepository,
          GlobalFoodItemRepository
        >
    with $Provider<GlobalFoodItemRepository> {
  /// Global food item repository.
  GlobalFoodItemRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalFoodItemRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalFoodItemRepositoryHash();

  @$internal
  @override
  $ProviderElement<GlobalFoodItemRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GlobalFoodItemRepository create(Ref ref) {
    return globalFoodItemRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobalFoodItemRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlobalFoodItemRepository>(value),
    );
  }
}

String _$globalFoodItemRepositoryHash() =>
    r'1fffcaa946f787a0a666f6980112f6fc424d1cc7';
