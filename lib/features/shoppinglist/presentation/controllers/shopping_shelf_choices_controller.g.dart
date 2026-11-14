// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_shelf_choices_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The shelf the household chose per product, live. A read error is logged
/// and passed on; the views fall back to the catalog then.

@ProviderFor(ShoppingShelfChoicesController)
final shoppingShelfChoicesControllerProvider =
    ShoppingShelfChoicesControllerProvider._();

/// The shelf the household chose per product, live. A read error is logged
/// and passed on; the views fall back to the catalog then.
final class ShoppingShelfChoicesControllerProvider
    extends
        $StreamNotifierProvider<
          ShoppingShelfChoicesController,
          ShoppingShelfChoices
        > {
  /// The shelf the household chose per product, live. A read error is logged
  /// and passed on; the views fall back to the catalog then.
  ShoppingShelfChoicesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingShelfChoicesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingShelfChoicesControllerHash();

  @$internal
  @override
  ShoppingShelfChoicesController create() => ShoppingShelfChoicesController();
}

String _$shoppingShelfChoicesControllerHash() =>
    r'a0eb3a9551cef1e650cf8c82f01deff033cbd838';

/// The shelf the household chose per product, live. A read error is logged
/// and passed on; the views fall back to the catalog then.

abstract class _$ShoppingShelfChoicesController
    extends $StreamNotifier<ShoppingShelfChoices> {
  Stream<ShoppingShelfChoices> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ShoppingShelfChoices>, ShoppingShelfChoices>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ShoppingShelfChoices>,
                ShoppingShelfChoices
              >,
              AsyncValue<ShoppingShelfChoices>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
