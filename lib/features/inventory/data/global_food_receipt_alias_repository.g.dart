// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_food_receipt_alias_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The global food receipt alias repository provider.

@ProviderFor(globalFoodReceiptAliasRepository)
final globalFoodReceiptAliasRepositoryProvider =
    GlobalFoodReceiptAliasRepositoryProvider._();

/// The global food receipt alias repository provider.

final class GlobalFoodReceiptAliasRepositoryProvider
    extends
        $FunctionalProvider<
          GlobalFoodReceiptAliasRepository,
          GlobalFoodReceiptAliasRepository,
          GlobalFoodReceiptAliasRepository
        >
    with $Provider<GlobalFoodReceiptAliasRepository> {
  /// The global food receipt alias repository provider.
  GlobalFoodReceiptAliasRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalFoodReceiptAliasRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalFoodReceiptAliasRepositoryHash();

  @$internal
  @override
  $ProviderElement<GlobalFoodReceiptAliasRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GlobalFoodReceiptAliasRepository create(Ref ref) {
    return globalFoodReceiptAliasRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobalFoodReceiptAliasRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlobalFoodReceiptAliasRepository>(
        value,
      ),
    );
  }
}

String _$globalFoodReceiptAliasRepositoryHash() =>
    r'b5e53ee189fe0c0484876e51cfb189be29b40316';
