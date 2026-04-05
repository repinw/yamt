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
        isAutoDispose: true,
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
    r'13371643008ce927a2cf48ca49d8b12895507390';

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
