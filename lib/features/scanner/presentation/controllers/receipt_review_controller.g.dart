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
    r'c5b7d5364e02574fe6bdad9bea4b999fdd5fca86';

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
        dependencies: null,
        $allTransitiveDependencies: null,
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
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ReceiptReviewState, ReceiptReviewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReceiptReviewState, ReceiptReviewState>,
              ReceiptReviewState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
