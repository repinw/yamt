// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_shared_receipt_intent.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PendingSharedReceiptIntent)
final pendingSharedReceiptIntentProvider =
    PendingSharedReceiptIntentProvider._();

final class PendingSharedReceiptIntentProvider
    extends
        $NotifierProvider<PendingSharedReceiptIntent, SharedReceiptIntent?> {
  PendingSharedReceiptIntentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingSharedReceiptIntentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingSharedReceiptIntentHash();

  @$internal
  @override
  PendingSharedReceiptIntent create() => PendingSharedReceiptIntent();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedReceiptIntent? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedReceiptIntent?>(value),
    );
  }
}

String _$pendingSharedReceiptIntentHash() =>
    r'7c6ac203e753704c7aff69a3d5b176e2d5b450a8';

abstract class _$PendingSharedReceiptIntent
    extends $Notifier<SharedReceiptIntent?> {
  SharedReceiptIntent? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SharedReceiptIntent?, SharedReceiptIntent?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SharedReceiptIntent?, SharedReceiptIntent?>,
              SharedReceiptIntent?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
