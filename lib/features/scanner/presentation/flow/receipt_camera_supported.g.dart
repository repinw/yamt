// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_camera_supported.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Returns whether receipt camera capture is supported on current platform.

@ProviderFor(receiptCameraSupported)
final receiptCameraSupportedProvider = ReceiptCameraSupportedProvider._();

/// Returns whether receipt camera capture is supported on current platform.

final class ReceiptCameraSupportedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Returns whether receipt camera capture is supported on current platform.
  ReceiptCameraSupportedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptCameraSupportedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptCameraSupportedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return receiptCameraSupported(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$receiptCameraSupportedHash() =>
    r'77e6d32f51011696e5c36aaaf145c26a6168aa86';
