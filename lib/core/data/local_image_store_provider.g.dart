// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_image_store_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Creates platform-specific local image store implementation.

@ProviderFor(localImageStore)
final localImageStoreProvider = LocalImageStoreProvider._();

/// Creates platform-specific local image store implementation.

final class LocalImageStoreProvider
    extends
        $FunctionalProvider<LocalImageStore, LocalImageStore, LocalImageStore>
    with $Provider<LocalImageStore> {
  /// Creates platform-specific local image store implementation.
  LocalImageStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localImageStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localImageStoreHash();

  @$internal
  @override
  $ProviderElement<LocalImageStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocalImageStore create(Ref ref) {
    return localImageStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalImageStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalImageStore>(value),
    );
  }
}

String _$localImageStoreHash() => r'cd3edd7b42fa1eb73119eb4056fbb1dc41474804';

/// Reads image bytes for one local image reference.

@ProviderFor(localImageBytes)
final localImageBytesProvider = LocalImageBytesFamily._();

/// Reads image bytes for one local image reference.

final class LocalImageBytesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Uint8List?>,
          Uint8List?,
          FutureOr<Uint8List?>
        >
    with $FutureModifier<Uint8List?>, $FutureProvider<Uint8List?> {
  /// Reads image bytes for one local image reference.
  LocalImageBytesProvider._({
    required LocalImageBytesFamily super.from,
    required LocalImageRef super.argument,
  }) : super(
         retry: null,
         name: r'localImageBytesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$localImageBytesHash();

  @override
  String toString() {
    return r'localImageBytesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Uint8List?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Uint8List?> create(Ref ref) {
    final argument = this.argument as LocalImageRef;
    return localImageBytes(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LocalImageBytesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$localImageBytesHash() => r'7158fe71b542012164a5d25fd953485c7ac12173';

/// Reads image bytes for one local image reference.

final class LocalImageBytesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Uint8List?>, LocalImageRef> {
  LocalImageBytesFamily._()
    : super(
        retry: null,
        name: r'localImageBytesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Reads image bytes for one local image reference.

  LocalImageBytesProvider call(LocalImageRef imageRef) =>
      LocalImageBytesProvider._(argument: imageRef, from: this);

  @override
  String toString() => r'localImageBytesProvider';
}
