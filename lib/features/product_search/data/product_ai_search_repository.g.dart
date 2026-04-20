// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_ai_search_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Product AI search repository provider.

@ProviderFor(productAiSearchRepository)
final productAiSearchRepositoryProvider = ProductAiSearchRepositoryProvider._();

/// Product AI search repository provider.

final class ProductAiSearchRepositoryProvider
    extends
        $FunctionalProvider<
          FirebaseProductAiSearchRepository,
          FirebaseProductAiSearchRepository,
          FirebaseProductAiSearchRepository
        >
    with $Provider<FirebaseProductAiSearchRepository> {
  /// Product AI search repository provider.
  ProductAiSearchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productAiSearchRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productAiSearchRepositoryHash();

  @$internal
  @override
  $ProviderElement<FirebaseProductAiSearchRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseProductAiSearchRepository create(Ref ref) {
    return productAiSearchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseProductAiSearchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseProductAiSearchRepository>(
        value,
      ),
    );
  }
}

String _$productAiSearchRepositoryHash() =>
    r'792346d73822c8a788ffb23b383c474834fc3f48';
