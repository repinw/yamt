// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ShoppingListController)
final shoppingListControllerProvider = ShoppingListControllerProvider._();

final class ShoppingListControllerProvider
    extends $NotifierProvider<ShoppingListController, List<ShoppingListItem>> {
  ShoppingListControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingListControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingListControllerHash();

  @$internal
  @override
  ShoppingListController create() => ShoppingListController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ShoppingListItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ShoppingListItem>>(value),
    );
  }
}

String _$shoppingListControllerHash() =>
    r'067197d91afbf41d9fb3a7495d47e4f2eedbb2d0';

abstract class _$ShoppingListController
    extends $Notifier<List<ShoppingListItem>> {
  List<ShoppingListItem> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<List<ShoppingListItem>, List<ShoppingListItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<ShoppingListItem>, List<ShoppingListItem>>,
              List<ShoppingListItem>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
