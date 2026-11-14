// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_shelf_choice_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The shelf choices of the current household.

@ProviderFor(shoppingShelfChoiceRepository)
final shoppingShelfChoiceRepositoryProvider =
    ShoppingShelfChoiceRepositoryProvider._();

/// The shelf choices of the current household.

final class ShoppingShelfChoiceRepositoryProvider
    extends
        $FunctionalProvider<
          ShoppingShelfChoiceRepository,
          ShoppingShelfChoiceRepository,
          ShoppingShelfChoiceRepository
        >
    with $Provider<ShoppingShelfChoiceRepository> {
  /// The shelf choices of the current household.
  ShoppingShelfChoiceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingShelfChoiceRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingShelfChoiceRepositoryHash();

  @$internal
  @override
  $ProviderElement<ShoppingShelfChoiceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShoppingShelfChoiceRepository create(Ref ref) {
    return shoppingShelfChoiceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShoppingShelfChoiceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShoppingShelfChoiceRepository>(
        value,
      ),
    );
  }
}

String _$shoppingShelfChoiceRepositoryHash() =>
    r'f961c5d0bc25011e34bea5a4feb78eb64c8b2ebd';
