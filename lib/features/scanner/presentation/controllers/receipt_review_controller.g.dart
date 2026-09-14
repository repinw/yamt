// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_review_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller managing the receipt review flow and modifications.

@ProviderFor(ReceiptReviewController)
final receiptReviewControllerProvider = ReceiptReviewControllerFamily._();

/// Controller managing the receipt review flow and modifications.
final class ReceiptReviewControllerProvider
    extends $NotifierProvider<ReceiptReviewController, ReceiptReviewState> {
  /// Controller managing the receipt review flow and modifications.
  ReceiptReviewControllerProvider._({
    required ReceiptReviewControllerFamily super.from,
    required ScannedReceipt super.argument,
  }) : super(
         retry: null,
         name: r'receiptReviewControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = receiptProductResolverProvider;
  static final $allTransitiveDependencies1 = receiptStorageGatewayProvider;
  static final $allTransitiveDependencies2 =
      ReceiptStorageGatewayProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$receiptReviewControllerHash();

  @override
  String toString() {
    return r'receiptReviewControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ReceiptReviewController create() => ReceiptReviewController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptReviewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptReviewState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReceiptReviewControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$receiptReviewControllerHash() =>
    r'e438b2dc3cf6669d33a1c2e82cf4fe268ebd0226';

/// Controller managing the receipt review flow and modifications.

final class ReceiptReviewControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ReceiptReviewController,
          ReceiptReviewState,
          ReceiptReviewState,
          ReceiptReviewState,
          ScannedReceipt
        > {
  ReceiptReviewControllerFamily._()
    : super(
        retry: null,
        name: r'receiptReviewControllerProvider',
        dependencies: <ProviderOrFamily>[
          receiptProductResolverProvider,
          receiptStorageGatewayProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ReceiptReviewControllerProvider.$allTransitiveDependencies0,
          ReceiptReviewControllerProvider.$allTransitiveDependencies1,
          ReceiptReviewControllerProvider.$allTransitiveDependencies2,
        ],
        isAutoDispose: true,
      );

  /// Controller managing the receipt review flow and modifications.

  ReceiptReviewControllerProvider call(ScannedReceipt initialReceipt) =>
      ReceiptReviewControllerProvider._(argument: initialReceipt, from: this);

  @override
  String toString() => r'receiptReviewControllerProvider';
}

/// Controller managing the receipt review flow and modifications.

abstract class _$ReceiptReviewController extends $Notifier<ReceiptReviewState> {
  late final _$args = ref.$arg as ScannedReceipt;
  ScannedReceipt get initialReceipt => _$args;

  ReceiptReviewState build(ScannedReceipt initialReceipt);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ReceiptReviewState, ReceiptReviewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReceiptReviewState, ReceiptReviewState>,
              ReceiptReviewState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
