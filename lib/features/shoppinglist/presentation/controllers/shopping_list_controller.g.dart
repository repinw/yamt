// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns realtime list state and serialized, optimistic mutations.

@ProviderFor(ShoppingListController)
final shoppingListControllerProvider = ShoppingListControllerProvider._();

/// Owns realtime list state and serialized, optimistic mutations.
final class ShoppingListControllerProvider
    extends
        $AsyncNotifierProvider<ShoppingListController, List<ShoppingListItem>> {
  /// Owns realtime list state and serialized, optimistic mutations.
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
    r'b36ff91f603c1dd8cd26a52bfa0a0a1ecd045a86';

/// Owns realtime list state and serialized, optimistic mutations.

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
