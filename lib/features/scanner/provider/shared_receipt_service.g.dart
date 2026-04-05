// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_receipt_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fileShareIntent)
final fileShareIntentProvider = FileShareIntentProvider._();

final class FileShareIntentProvider
    extends
        $FunctionalProvider<FileShareIntent, FileShareIntent, FileShareIntent>
    with $Provider<FileShareIntent> {
  FileShareIntentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileShareIntentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileShareIntentHash();

  @$internal
  @override
  $ProviderElement<FileShareIntent> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FileShareIntent create(Ref ref) {
    return fileShareIntent(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileShareIntent value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileShareIntent>(value),
    );
  }
}

String _$fileShareIntentHash() => r'65394a6e885527bd2436bd6da386ca3671143feb';

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

@ProviderFor(SharedReceiptService)
final sharedReceiptServiceProvider = SharedReceiptServiceProvider._();

final class SharedReceiptServiceProvider
    extends $AsyncNotifierProvider<SharedReceiptService, void> {
  SharedReceiptServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedReceiptServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedReceiptServiceHash();

  @$internal
  @override
  SharedReceiptService create() => SharedReceiptService();
}

String _$sharedReceiptServiceHash() =>
    r'6b9c6a11cfea56baf5f150570c3e2a3c9c266455';

abstract class _$SharedReceiptService extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
