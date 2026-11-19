// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_open_count.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How many entries are still to buy on the household list and the private
/// list together. It is loading while the list loads and an error when the
/// list cannot be read, never 0 in their place.

@ProviderFor(openShoppingListCount)
final openShoppingListCountProvider = OpenShoppingListCountProvider._();

/// How many entries are still to buy on the household list and the private
/// list together. It is loading while the list loads and an error when the
/// list cannot be read, never 0 in their place.

final class OpenShoppingListCountProvider
    extends
        $FunctionalProvider<AsyncValue<int>, AsyncValue<int>, AsyncValue<int>>
    with $Provider<AsyncValue<int>> {
  /// How many entries are still to buy on the household list and the private
  /// list together. It is loading while the list loads and an error when the
  /// list cannot be read, never 0 in their place.
  OpenShoppingListCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openShoppingListCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openShoppingListCountHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AsyncValue<int> create(Ref ref) {
    return openShoppingListCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<int>>(value),
    );
  }
}

String _$openShoppingListCountHash() =>
    r'1c7f961a0743ae7ae39752ed00a3922ad01bda02';
