// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_upload_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Photo upload repository. Kept alive, so it knows the uploads that run
/// while pages come and go.

@ProviderFor(photoUploadRepository)
final photoUploadRepositoryProvider = PhotoUploadRepositoryProvider._();

/// Photo upload repository. Kept alive, so it knows the uploads that run
/// while pages come and go.

final class PhotoUploadRepositoryProvider
    extends
        $FunctionalProvider<
          PhotoUploadRepository,
          PhotoUploadRepository,
          PhotoUploadRepository
        >
    with $Provider<PhotoUploadRepository> {
  /// Photo upload repository. Kept alive, so it knows the uploads that run
  /// while pages come and go.
  PhotoUploadRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoUploadRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoUploadRepositoryHash();

  @$internal
  @override
  $ProviderElement<PhotoUploadRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PhotoUploadRepository create(Ref ref) {
    return photoUploadRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoUploadRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoUploadRepository>(value),
    );
  }
}

String _$photoUploadRepositoryHash() =>
    r'00497f4b41ef5a3ec53fdcb71155d7205fe04932';
