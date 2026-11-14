// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_import_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shopping list import repository.

@ProviderFor(shoppingListImportRepository)
final shoppingListImportRepositoryProvider =
    ShoppingListImportRepositoryProvider._();

/// Shopping list import repository.

final class ShoppingListImportRepositoryProvider
    extends
        $FunctionalProvider<
          ShoppingListImportRepository,
          ShoppingListImportRepository,
          ShoppingListImportRepository
        >
    with $Provider<ShoppingListImportRepository> {
  /// Shopping list import repository.
  ShoppingListImportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingListImportRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingListImportRepositoryHash();

  @$internal
  @override
  $ProviderElement<ShoppingListImportRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShoppingListImportRepository create(Ref ref) {
    return shoppingListImportRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShoppingListImportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShoppingListImportRepository>(value),
    );
  }
}

String _$shoppingListImportRepositoryHash() =>
    r'23342ee2b1c8b8ac5746af102fa3ee73953ee36f';
