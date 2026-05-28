// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_review_sheet_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controls receipt review sheet state and candidate resolution.

@ProviderFor(ReceiptReviewSheetController)
final receiptReviewSheetControllerProvider =
    ReceiptReviewSheetControllerFamily._();

/// Controls receipt review sheet state and candidate resolution.
final class ReceiptReviewSheetControllerProvider
    extends
        $NotifierProvider<
          ReceiptReviewSheetController,
          ReceiptReviewSheetState
        > {
  /// Controls receipt review sheet state and candidate resolution.
  ReceiptReviewSheetControllerProvider._({
    required ReceiptReviewSheetControllerFamily super.from,
    required List<ReceiptReviewItemDraft> super.argument,
  }) : super(
         retry: null,
         name: r'receiptReviewSheetControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$receiptReviewSheetControllerHash();

  @override
  String toString() {
    return r'receiptReviewSheetControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ReceiptReviewSheetController create() => ReceiptReviewSheetController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptReviewSheetState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptReviewSheetState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReceiptReviewSheetControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$receiptReviewSheetControllerHash() =>
    r'034f9b0af24b66f79f8d064eb00ebfcc1b87939c';

/// Controls receipt review sheet state and candidate resolution.

final class ReceiptReviewSheetControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ReceiptReviewSheetController,
          ReceiptReviewSheetState,
          ReceiptReviewSheetState,
          ReceiptReviewSheetState,
          List<ReceiptReviewItemDraft>
        > {
  ReceiptReviewSheetControllerFamily._()
    : super(
        retry: null,
        name: r'receiptReviewSheetControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Controls receipt review sheet state and candidate resolution.

  ReceiptReviewSheetControllerProvider call(
    List<ReceiptReviewItemDraft> initialItems,
  ) => ReceiptReviewSheetControllerProvider._(
    argument: initialItems,
    from: this,
  );

  @override
  String toString() => r'receiptReviewSheetControllerProvider';
}

/// Controls receipt review sheet state and candidate resolution.

abstract class _$ReceiptReviewSheetController
    extends $Notifier<ReceiptReviewSheetState> {
  late final _$args = ref.$arg as List<ReceiptReviewItemDraft>;
  List<ReceiptReviewItemDraft> get initialItems => _$args;

  ReceiptReviewSheetState build(List<ReceiptReviewItemDraft> initialItems);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<ReceiptReviewSheetState, ReceiptReviewSheetState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReceiptReviewSheetState, ReceiptReviewSheetState>,
              ReceiptReviewSheetState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
