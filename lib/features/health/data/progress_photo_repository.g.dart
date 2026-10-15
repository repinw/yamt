// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_photo_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Progress photo repository of the signed-in user.

@ProviderFor(progressPhotoRepository)
final progressPhotoRepositoryProvider = ProgressPhotoRepositoryProvider._();

/// Progress photo repository of the signed-in user.

final class ProgressPhotoRepositoryProvider
    extends
        $FunctionalProvider<
          ProgressPhotoRepository,
          ProgressPhotoRepository,
          ProgressPhotoRepository
        >
    with $Provider<ProgressPhotoRepository> {
  /// Progress photo repository of the signed-in user.
  ProgressPhotoRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressPhotoRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressPhotoRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProgressPhotoRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProgressPhotoRepository create(Ref ref) {
    return progressPhotoRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgressPhotoRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgressPhotoRepository>(value),
    );
  }
}

String _$progressPhotoRepositoryHash() =>
    r'0abcb314c68c47d59b6b82c75d16648c0923cba8';

/// The progress photos of the signed-in user, oldest day first.

@ProviderFor(progressPhotos)
final progressPhotosProvider = ProgressPhotosProvider._();

/// The progress photos of the signed-in user, oldest day first.

final class ProgressPhotosProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProgressPhoto>>,
          List<ProgressPhoto>,
          Stream<List<ProgressPhoto>>
        >
    with
        $FutureModifier<List<ProgressPhoto>>,
        $StreamProvider<List<ProgressPhoto>> {
  /// The progress photos of the signed-in user, oldest day first.
  ProgressPhotosProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressPhotosProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressPhotosHash();

  @$internal
  @override
  $StreamProviderElement<List<ProgressPhoto>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ProgressPhoto>> create(Ref ref) {
    return progressPhotos(ref);
  }
}

String _$progressPhotosHash() => r'ef21c3a139a99ffb3be2b7ece526f3166fdbdf97';

/// Whether a photo of [pose] exists on [day], so a new one replaces it.

@ProviderFor(progressPhotoExists)
final progressPhotoExistsProvider = ProgressPhotoExistsFamily._();

/// Whether a photo of [pose] exists on [day], so a new one replaces it.

final class ProgressPhotoExistsProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether a photo of [pose] exists on [day], so a new one replaces it.
  ProgressPhotoExistsProvider._({
    required ProgressPhotoExistsFamily super.from,
    required (DateTime, ProgressPhotoPose) super.argument,
  }) : super(
         retry: null,
         name: r'progressPhotoExistsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$progressPhotoExistsHash();

  @override
  String toString() {
    return r'progressPhotoExistsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as (DateTime, ProgressPhotoPose);
    return progressPhotoExists(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProgressPhotoExistsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$progressPhotoExistsHash() =>
    r'5670abfc2e5b527dcdc7348113ba4ece2542bbfc';

/// Whether a photo of [pose] exists on [day], so a new one replaces it.

final class ProgressPhotoExistsFamily extends $Family
    with $FunctionalFamilyOverride<bool, (DateTime, ProgressPhotoPose)> {
  ProgressPhotoExistsFamily._()
    : super(
        retry: null,
        name: r'progressPhotoExistsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether a photo of [pose] exists on [day], so a new one replaces it.

  ProgressPhotoExistsProvider call(DateTime day, ProgressPhotoPose pose) =>
      ProgressPhotoExistsProvider._(argument: (day, pose), from: this);

  @override
  String toString() => r'progressPhotoExistsProvider';
}
