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
    extends
        $FunctionalProvider<
          ReceiptFilePicker,
          ReceiptFilePicker,
          ReceiptFilePicker
        >
    with $Provider<ReceiptFilePicker> {
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
  $ProviderElement<ReceiptFilePicker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptFilePicker create(Ref ref) {
    return filePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptFilePicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptFilePicker>(value),
    );
  }
}

String _$filePickerHash() => r'8efe115e064e993f5730f7fc74b29da429daed41';

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
