// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_scope_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether someone else shares the household list. True until the members
/// are known, so the choice does not flicker away for a shared household.

@ProviderFor(shoppingListIsShared)
final shoppingListIsSharedProvider = ShoppingListIsSharedProvider._();

/// Whether someone else shares the household list. True until the members
/// are known, so the choice does not flicker away for a shared household.

final class ShoppingListIsSharedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether someone else shares the household list. True until the members
  /// are known, so the choice does not flicker away for a shared household.
  ShoppingListIsSharedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingListIsSharedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingListIsSharedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return shoppingListIsShared(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$shoppingListIsSharedHash() =>
    r'9f7ee1784318c20767d2ae93930b69ccbb4e0445';

/// The list the page shows, saved on the device. The household list until
/// the user switches. Alone in the household, both lists are one: then it
/// shows everything. The choice lives in the preferences, so the controller
/// need not stay alive.

@ProviderFor(ShoppingListScopeController)
final shoppingListScopeControllerProvider =
    ShoppingListScopeControllerProvider._();

/// The list the page shows, saved on the device. The household list until
/// the user switches. Alone in the household, both lists are one: then it
/// shows everything. The choice lives in the preferences, so the controller
/// need not stay alive.
final class ShoppingListScopeControllerProvider
    extends $NotifierProvider<ShoppingListScopeController, ShoppingListScope> {
  /// The list the page shows, saved on the device. The household list until
  /// the user switches. Alone in the household, both lists are one: then it
  /// shows everything. The choice lives in the preferences, so the controller
  /// need not stay alive.
  ShoppingListScopeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingListScopeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingListScopeControllerHash();

  @$internal
  @override
  ShoppingListScopeController create() => ShoppingListScopeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShoppingListScope value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShoppingListScope>(value),
    );
  }
}

String _$shoppingListScopeControllerHash() =>
    r'8f08d067ed440387902aad242f0c2d76d48cceb1';

/// The list the page shows, saved on the device. The household list until
/// the user switches. Alone in the household, both lists are one: then it
/// shows everything. The choice lives in the preferences, so the controller
/// need not stay alive.

abstract class _$ShoppingListScopeController
    extends $Notifier<ShoppingListScope> {
  ShoppingListScope build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ShoppingListScope, ShoppingListScope>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ShoppingListScope, ShoppingListScope>,
              ShoppingListScope,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
