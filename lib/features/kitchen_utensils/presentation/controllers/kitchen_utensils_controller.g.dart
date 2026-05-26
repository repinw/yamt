// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kitchen_utensils_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Kitchen utensils controller.

@ProviderFor(KitchenUtensilsController)
final kitchenUtensilsControllerProvider = KitchenUtensilsControllerProvider._();

/// Kitchen utensils controller.
final class KitchenUtensilsControllerProvider
    extends
        $AsyncNotifierProvider<
          KitchenUtensilsController,
          List<KitchenUtensil>
        > {
  /// Kitchen utensils controller.
  KitchenUtensilsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kitchenUtensilsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kitchenUtensilsControllerHash();

  @$internal
  @override
  KitchenUtensilsController create() => KitchenUtensilsController();
}

String _$kitchenUtensilsControllerHash() =>
    r'ede168765c770ba126c789a88f7a07a0e30fcf58';

/// Kitchen utensils controller.

abstract class _$KitchenUtensilsController
    extends $AsyncNotifier<List<KitchenUtensil>> {
  FutureOr<List<KitchenUtensil>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<KitchenUtensil>>, List<KitchenUtensil>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<KitchenUtensil>>,
                List<KitchenUtensil>
              >,
              AsyncValue<List<KitchenUtensil>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
