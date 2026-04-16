// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_input_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Image picker.

@ProviderFor(imagePicker)
final imagePickerProvider = ImagePickerProvider._();

/// Image picker.

final class ImagePickerProvider
    extends $FunctionalProvider<ImagePicker, ImagePicker, ImagePicker>
    with $Provider<ImagePicker> {
  /// Image picker.
  ImagePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imagePickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imagePickerHash();

  @$internal
  @override
  $ProviderElement<ImagePicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImagePicker create(Ref ref) {
    return imagePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImagePicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImagePicker>(value),
    );
  }
}

String _$imagePickerHash() => r'7877699a862be48e962306635347623c45e91971';

/// File picker.

@ProviderFor(filePicker)
final filePickerProvider = FilePickerProvider._();

/// File picker.

final class FilePickerProvider
    extends $FunctionalProvider<FilePicker, FilePicker, FilePicker>
    with $Provider<FilePicker> {
  /// File picker.
  FilePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filePickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filePickerHash();

  @$internal
  @override
  $ProviderElement<FilePicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FilePicker create(Ref ref) {
    return filePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FilePicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FilePicker>(value),
    );
  }
}

String _$filePickerHash() => r'bae1fe0c95c85532cffec63b62cfe564b8356d75';

/// Receipt input repository.

@ProviderFor(receiptInputRepository)
final receiptInputRepositoryProvider = ReceiptInputRepositoryProvider._();

/// Receipt input repository.

final class ReceiptInputRepositoryProvider
    extends
        $FunctionalProvider<
          ReceiptInputRepository,
          ReceiptInputRepository,
          ReceiptInputRepository
        >
    with $Provider<ReceiptInputRepository> {
  /// Receipt input repository.
  ReceiptInputRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptInputRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptInputRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReceiptInputRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptInputRepository create(Ref ref) {
    return receiptInputRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptInputRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptInputRepository>(value),
    );
  }
}

String _$receiptInputRepositoryHash() =>
    r'd7db312d54ac4d1b64927f93b0c4a138a432234e';
