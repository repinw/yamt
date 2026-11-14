// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_private_list_status.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the private list failed to load. The household list still shows;
/// the page offers a retry for the private one. Checked again whenever the
/// list changes.

@ProviderFor(shoppingPrivateListFailed)
final shoppingPrivateListFailedProvider = ShoppingPrivateListFailedProvider._();

/// Whether the private list failed to load. The household list still shows;
/// the page offers a retry for the private one. Checked again whenever the
/// list changes.

final class ShoppingPrivateListFailedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the private list failed to load. The household list still shows;
  /// the page offers a retry for the private one. Checked again whenever the
  /// list changes.
  ShoppingPrivateListFailedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingPrivateListFailedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingPrivateListFailedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return shoppingPrivateListFailed(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$shoppingPrivateListFailedHash() =>
    r'276450abe149d7526ac1852d6e6fc73935df22af';
