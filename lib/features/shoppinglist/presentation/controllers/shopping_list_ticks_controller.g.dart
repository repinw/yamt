// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_ticks_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds [ShoppingListTicks] while the list page shows. Saves run one after
/// another, so the stored list can lag behind the finger.

@ProviderFor(ShoppingListTicksController)
final shoppingListTicksControllerProvider =
    ShoppingListTicksControllerProvider._();

/// Holds [ShoppingListTicks] while the list page shows. Saves run one after
/// another, so the stored list can lag behind the finger.
final class ShoppingListTicksControllerProvider
    extends $NotifierProvider<ShoppingListTicksController, ShoppingListTicks> {
  /// Holds [ShoppingListTicks] while the list page shows. Saves run one after
  /// another, so the stored list can lag behind the finger.
  ShoppingListTicksControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingListTicksControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingListTicksControllerHash();

  @$internal
  @override
  ShoppingListTicksController create() => ShoppingListTicksController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShoppingListTicks value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShoppingListTicks>(value),
    );
  }
}

String _$shoppingListTicksControllerHash() =>
    r'6b1b397fe24877c21c6a7a34cc3aef194d3be540';

/// Holds [ShoppingListTicks] while the list page shows. Saves run one after
/// another, so the stored list can lag behind the finger.

abstract class _$ShoppingListTicksController
    extends $Notifier<ShoppingListTicks> {
  ShoppingListTicks build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ShoppingListTicks, ShoppingListTicks>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ShoppingListTicks, ShoppingListTicks>,
              ShoppingListTicks,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
