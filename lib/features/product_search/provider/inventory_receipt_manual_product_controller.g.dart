// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_receipt_manual_product_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InventoryReceiptManualProductController)
final inventoryReceiptManualProductControllerProvider =
    InventoryReceiptManualProductControllerFamily._();

final class InventoryReceiptManualProductControllerProvider
    extends
        $NotifierProvider<
          InventoryReceiptManualProductController,
          InventoryReceiptManualProductState
        > {
  InventoryReceiptManualProductControllerProvider._({
    required InventoryReceiptManualProductControllerFamily super.from,
    required InventoryReceiptManualProductConfig super.argument,
  }) : super(
         retry: null,
         name: r'inventoryReceiptManualProductControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$inventoryReceiptManualProductControllerHash();

  @override
  String toString() {
    return r'inventoryReceiptManualProductControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  InventoryReceiptManualProductController create() =>
      InventoryReceiptManualProductController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryReceiptManualProductState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryReceiptManualProductState>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InventoryReceiptManualProductControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inventoryReceiptManualProductControllerHash() =>
    r'dc77b3f506193d9873b2737a622ec52538f4aa24';

final class InventoryReceiptManualProductControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          InventoryReceiptManualProductController,
          InventoryReceiptManualProductState,
          InventoryReceiptManualProductState,
          InventoryReceiptManualProductState,
          InventoryReceiptManualProductConfig
        > {
  InventoryReceiptManualProductControllerFamily._()
    : super(
        retry: null,
        name: r'inventoryReceiptManualProductControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InventoryReceiptManualProductControllerProvider call(
    InventoryReceiptManualProductConfig config,
  ) => InventoryReceiptManualProductControllerProvider._(
    argument: config,
    from: this,
  );

  @override
  String toString() => r'inventoryReceiptManualProductControllerProvider';
}

abstract class _$InventoryReceiptManualProductController
    extends $Notifier<InventoryReceiptManualProductState> {
  late final _$args = ref.$arg as InventoryReceiptManualProductConfig;
  InventoryReceiptManualProductConfig get config => _$args;

  InventoryReceiptManualProductState build(
    InventoryReceiptManualProductConfig config,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              InventoryReceiptManualProductState,
              InventoryReceiptManualProductState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                InventoryReceiptManualProductState,
                InventoryReceiptManualProductState
              >,
              InventoryReceiptManualProductState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
