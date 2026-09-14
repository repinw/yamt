// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_shared_receipt_paths.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds pending shared receipt file paths waiting to be confirmed
/// and processed.

@ProviderFor(PendingSharedReceiptPaths)
final pendingSharedReceiptPathsProvider = PendingSharedReceiptPathsProvider._();

/// Holds pending shared receipt file paths waiting to be confirmed
/// and processed.
final class PendingSharedReceiptPathsProvider
    extends $NotifierProvider<PendingSharedReceiptPaths, List<String>?> {
  /// Holds pending shared receipt file paths waiting to be confirmed
  /// and processed.
  PendingSharedReceiptPathsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingSharedReceiptPathsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingSharedReceiptPathsHash();

  @$internal
  @override
  PendingSharedReceiptPaths create() => PendingSharedReceiptPaths();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>?>(value),
    );
  }
}

String _$pendingSharedReceiptPathsHash() =>
    r'2bb30f4ea1cf51d66a4d4b64ba0640349f2b19cb';

/// Holds pending shared receipt file paths waiting to be confirmed
/// and processed.

abstract class _$PendingSharedReceiptPaths extends $Notifier<List<String>?> {
  List<String>? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<String>?, List<String>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>?, List<String>?>,
              List<String>?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
