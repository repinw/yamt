// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_receipt_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// File share intent.

@ProviderFor(fileShareIntent)
final fileShareIntentProvider = FileShareIntentProvider._();

/// File share intent.

final class FileShareIntentProvider
    extends
        $FunctionalProvider<FileShareIntent, FileShareIntent, FileShareIntent>
    with $Provider<FileShareIntent> {
  /// File share intent.
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

/// Defines shared receipt service.

@ProviderFor(SharedReceiptService)
final sharedReceiptServiceProvider = SharedReceiptServiceProvider._();

/// Defines shared receipt service.
final class SharedReceiptServiceProvider
    extends $AsyncNotifierProvider<SharedReceiptService, void> {
  /// Defines shared receipt service.
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
    r'961323c42e127b282c407361941f035cef5b5b7c';

/// Defines shared receipt service.

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
