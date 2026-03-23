// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'off_product_search_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(offProductSearchRepository)
final offProductSearchRepositoryProvider =
    OffProductSearchRepositoryProvider._();

final class OffProductSearchRepositoryProvider
    extends
        $FunctionalProvider<
          OffProductSearchRepository,
          OffProductSearchRepository,
          OffProductSearchRepository
        >
    with $Provider<OffProductSearchRepository> {
  OffProductSearchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offProductSearchRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offProductSearchRepositoryHash();

  @$internal
  @override
  $ProviderElement<OffProductSearchRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OffProductSearchRepository create(Ref ref) {
    return offProductSearchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OffProductSearchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OffProductSearchRepository>(value),
    );
  }
}

String _$offProductSearchRepositoryHash() =>
    r'3a17006ed963005160028106bec5b755e26928be';
