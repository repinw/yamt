// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_photo_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Product photo repository.

@ProviderFor(productPhotoRepository)
final productPhotoRepositoryProvider = ProductPhotoRepositoryProvider._();

/// Product photo repository.

final class ProductPhotoRepositoryProvider
    extends
        $FunctionalProvider<
          ProductPhotoRepository,
          ProductPhotoRepository,
          ProductPhotoRepository
        >
    with $Provider<ProductPhotoRepository> {
  /// Product photo repository.
  ProductPhotoRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productPhotoRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productPhotoRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProductPhotoRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductPhotoRepository create(Ref ref) {
    return productPhotoRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductPhotoRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductPhotoRepository>(value),
    );
  }
}

String _$productPhotoRepositoryHash() =>
    r'64fa5a8efc021b4e3c80d5a707a8951a0dc4190c';
