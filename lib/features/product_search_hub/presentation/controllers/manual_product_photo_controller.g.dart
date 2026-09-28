// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_product_photo_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Takes the package photos of the product editor, reads them into the
/// product, and stores them when the product is saved.
///
/// The barcode scanner looks at every photo first. Only when it finds no
/// barcode does the barcode the AI read on the front count.

@ProviderFor(ManualProductPhotoController)
final manualProductPhotoControllerProvider =
    ManualProductPhotoControllerFamily._();

/// Takes the package photos of the product editor, reads them into the
/// product, and stores them when the product is saved.
///
/// The barcode scanner looks at every photo first. Only when it finds no
/// barcode does the barcode the AI read on the front count.
final class ManualProductPhotoControllerProvider
    extends
        $NotifierProvider<
          ManualProductPhotoController,
          ManualProductPhotoState
        > {
  /// Takes the package photos of the product editor, reads them into the
  /// product, and stores them when the product is saved.
  ///
  /// The barcode scanner looks at every photo first. Only when it finds no
  /// barcode does the barcode the AI read on the front count.
  ManualProductPhotoControllerProvider._({
    required ManualProductPhotoControllerFamily super.from,
    required InventoryReceiptManualProductConfig super.argument,
  }) : super(
         retry: null,
         name: r'manualProductPhotoControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$manualProductPhotoControllerHash();

  @override
  String toString() {
    return r'manualProductPhotoControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ManualProductPhotoController create() => ManualProductPhotoController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ManualProductPhotoState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ManualProductPhotoState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ManualProductPhotoControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$manualProductPhotoControllerHash() =>
    r'a7a35170a872c0fa947739966f0ac5ae8c8585b0';

/// Takes the package photos of the product editor, reads them into the
/// product, and stores them when the product is saved.
///
/// The barcode scanner looks at every photo first. Only when it finds no
/// barcode does the barcode the AI read on the front count.

final class ManualProductPhotoControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ManualProductPhotoController,
          ManualProductPhotoState,
          ManualProductPhotoState,
          ManualProductPhotoState,
          InventoryReceiptManualProductConfig
        > {
  ManualProductPhotoControllerFamily._()
    : super(
        retry: null,
        name: r'manualProductPhotoControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Takes the package photos of the product editor, reads them into the
  /// product, and stores them when the product is saved.
  ///
  /// The barcode scanner looks at every photo first. Only when it finds no
  /// barcode does the barcode the AI read on the front count.

  ManualProductPhotoControllerProvider call(
    InventoryReceiptManualProductConfig config,
  ) => ManualProductPhotoControllerProvider._(argument: config, from: this);

  @override
  String toString() => r'manualProductPhotoControllerProvider';
}

/// Takes the package photos of the product editor, reads them into the
/// product, and stores them when the product is saved.
///
/// The barcode scanner looks at every photo first. Only when it finds no
/// barcode does the barcode the AI read on the front count.

abstract class _$ManualProductPhotoController
    extends $Notifier<ManualProductPhotoState> {
  late final _$args = ref.$arg as InventoryReceiptManualProductConfig;
  InventoryReceiptManualProductConfig get config => _$args;

  ManualProductPhotoState build(InventoryReceiptManualProductConfig config);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<ManualProductPhotoState, ManualProductPhotoState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ManualProductPhotoState, ManualProductPhotoState>,
              ManualProductPhotoState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
