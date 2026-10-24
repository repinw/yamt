// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_photo_upload_retry.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Uploads the photos that a failed or interrupted upload left on the
/// device, whenever the app starts or comes back to the foreground, a user
/// signs in, or the device comes back online. Signing out deletes them. `lib/app.dart` keeps it alive for
/// the app's lifetime. A failure only logs: the next run tries again.

@ProviderFor(pendingPhotoUploadRetry)
final pendingPhotoUploadRetryProvider = PendingPhotoUploadRetryProvider._();

/// Uploads the photos that a failed or interrupted upload left on the
/// device, whenever the app starts or comes back to the foreground, a user
/// signs in, or the device comes back online. Signing out deletes them. `lib/app.dart` keeps it alive for
/// the app's lifetime. A failure only logs: the next run tries again.

final class PendingPhotoUploadRetryProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Uploads the photos that a failed or interrupted upload left on the
  /// device, whenever the app starts or comes back to the foreground, a user
  /// signs in, or the device comes back online. Signing out deletes them. `lib/app.dart` keeps it alive for
  /// the app's lifetime. A failure only logs: the next run tries again.
  PendingPhotoUploadRetryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingPhotoUploadRetryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingPhotoUploadRetryHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return pendingPhotoUploadRetry(ref);
  }
}

String _$pendingPhotoUploadRetryHash() =>
    r'002378bd30c79915bc43002b64fca30b0a328bee';
