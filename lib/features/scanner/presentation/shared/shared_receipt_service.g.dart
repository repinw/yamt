// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_receipt_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides platform [FileShareIntent] instance.

@ProviderFor(fileShareIntent)
final fileShareIntentProvider = FileShareIntentProvider._();

/// Provides platform [FileShareIntent] instance.

final class FileShareIntentProvider
    extends
        $FunctionalProvider<FileShareIntent, FileShareIntent, FileShareIntent>
    with $Provider<FileShareIntent> {
  /// Provides platform [FileShareIntent] instance.
  FileShareIntentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileShareIntentProvider',
        isAutoDispose: false,
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

String _$fileShareIntentHash() => r'877187683456d9af03382b9e455b4597e4390f94';

/// Service that monitors platform file share intents and pushes valid paths
/// to [PendingSharedReceiptPaths]. Shared text and links go to
/// [PendingSharedText], and a share we cannot read raises
/// [PendingUnreadableShare].

@ProviderFor(SharedReceiptService)
final sharedReceiptServiceProvider = SharedReceiptServiceProvider._();

/// Service that monitors platform file share intents and pushes valid paths
/// to [PendingSharedReceiptPaths]. Shared text and links go to
/// [PendingSharedText], and a share we cannot read raises
/// [PendingUnreadableShare].
final class SharedReceiptServiceProvider
    extends $AsyncNotifierProvider<SharedReceiptService, void> {
  /// Service that monitors platform file share intents and pushes valid paths
  /// to [PendingSharedReceiptPaths]. Shared text and links go to
  /// [PendingSharedText], and a share we cannot read raises
  /// [PendingUnreadableShare].
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
    r'589929979d8b0d57915c6336d5e0663090b432f4';

/// Service that monitors platform file share intents and pushes valid paths
/// to [PendingSharedReceiptPaths]. Shared text and links go to
/// [PendingSharedText], and a share we cannot read raises
/// [PendingUnreadableShare].

abstract class _$SharedReceiptService extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
