// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fridge_item_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fridgeItemRepository)
final fridgeItemRepositoryProvider = FridgeItemRepositoryProvider._();

final class FridgeItemRepositoryProvider
    extends
        $FunctionalProvider<
          FridgeItemRepository,
          FridgeItemRepository,
          FridgeItemRepository
        >
    with $Provider<FridgeItemRepository> {
  FridgeItemRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fridgeItemRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fridgeItemRepositoryHash();

  @$internal
  @override
  $ProviderElement<FridgeItemRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FridgeItemRepository create(Ref ref) {
    return fridgeItemRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FridgeItemRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FridgeItemRepository>(value),
    );
  }
}

String _$fridgeItemRepositoryHash() =>
    r'ffc9afd4ddcbc3300c68d58356e630a7aee00cc5';
