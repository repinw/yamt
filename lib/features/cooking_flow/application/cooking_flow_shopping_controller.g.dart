// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_flow_shopping_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Coordinates cookflow shopping-list side effects.

@ProviderFor(CookingFlowShoppingController)
final cookingFlowShoppingControllerProvider =
    CookingFlowShoppingControllerProvider._();

/// Coordinates cookflow shopping-list side effects.
final class CookingFlowShoppingControllerProvider
    extends $NotifierProvider<CookingFlowShoppingController, void> {
  /// Coordinates cookflow shopping-list side effects.
  CookingFlowShoppingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookingFlowShoppingControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookingFlowShoppingControllerHash();

  @$internal
  @override
  CookingFlowShoppingController create() => CookingFlowShoppingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$cookingFlowShoppingControllerHash() =>
    r'333d32201e57af99bce8714c9dee4ec7fe76aea9';

/// Coordinates cookflow shopping-list side effects.

abstract class _$CookingFlowShoppingController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
