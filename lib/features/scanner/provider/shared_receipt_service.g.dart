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
    r'67c4d04b9edc4ec4bdbabaaf781e7284d535a60a';

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
