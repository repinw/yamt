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
    extends
        $AsyncNotifierProvider<ShoppingListController, List<ShoppingListItem>> {
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
}

String _$shoppingListControllerHash() =>
    r'67cbd920ab33ea8756add7fb4774c50235617172';

abstract class _$ShoppingListController
    extends $AsyncNotifier<List<ShoppingListItem>> {
  FutureOr<List<ShoppingListItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<ShoppingListItem>>, List<ShoppingListItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ShoppingListItem>>,
                List<ShoppingListItem>
              >,
              AsyncValue<List<ShoppingListItem>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
