// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_storage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Returns Storage instance unless session shutdown is in progress.

@ProviderFor(firebaseStorage)
final firebaseStorageProvider = FirebaseStorageProvider._();

/// Returns Storage instance unless session shutdown is in progress.

final class FirebaseStorageProvider
    extends
        $FunctionalProvider<
          FirebaseStorage?,
          FirebaseStorage?,
          FirebaseStorage?
        >
    with $Provider<FirebaseStorage?> {
  /// Returns Storage instance unless session shutdown is in progress.
  FirebaseStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseStorageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseStorageHash();

  @$internal
  @override
  $ProviderElement<FirebaseStorage?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseStorage? create(Ref ref) {
    return firebaseStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseStorage? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseStorage?>(value),
    );
  }
}

String _$firebaseStorageHash() => r'4c7e8396afda799e648b4df6f01860f26bba75e5';
