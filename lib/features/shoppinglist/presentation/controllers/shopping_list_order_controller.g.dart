// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_order_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The order of the list, saved on the device. By shelf until the user
/// switches.

@ProviderFor(ShoppingListOrderController)
final shoppingListOrderControllerProvider =
    ShoppingListOrderControllerProvider._();

/// The order of the list, saved on the device. By shelf until the user
/// switches.
final class ShoppingListOrderControllerProvider
    extends $NotifierProvider<ShoppingListOrderController, ShoppingListOrder> {
  /// The order of the list, saved on the device. By shelf until the user
  /// switches.
  ShoppingListOrderControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingListOrderControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingListOrderControllerHash();

  @$internal
  @override
  ShoppingListOrderController create() => ShoppingListOrderController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShoppingListOrder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShoppingListOrder>(value),
    );
  }
}

String _$shoppingListOrderControllerHash() =>
    r'f116a8110d6e5b80ea89100db7487402e33de6d0';

/// The order of the list, saved on the device. By shelf until the user
/// switches.

abstract class _$ShoppingListOrderController
    extends $Notifier<ShoppingListOrder> {
  ShoppingListOrder build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ShoppingListOrder, ShoppingListOrder>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ShoppingListOrder, ShoppingListOrder>,
              ShoppingListOrder,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
