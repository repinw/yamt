// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_run_shopping_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The pause of the household's cook runs for the shopping.

@ProviderFor(cookRunShoppingService)
final cookRunShoppingServiceProvider = CookRunShoppingServiceProvider._();

/// The pause of the household's cook runs for the shopping.

final class CookRunShoppingServiceProvider
    extends
        $FunctionalProvider<
          CookRunShoppingService,
          CookRunShoppingService,
          CookRunShoppingService
        >
    with $Provider<CookRunShoppingService> {
  /// The pause of the household's cook runs for the shopping.
  CookRunShoppingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookRunShoppingServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookRunShoppingServiceHash();

  @$internal
  @override
  $ProviderElement<CookRunShoppingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CookRunShoppingService create(Ref ref) {
    return cookRunShoppingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CookRunShoppingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CookRunShoppingService>(value),
    );
  }
}

String _$cookRunShoppingServiceHash() =>
    r'32da0df368b58f420b01738e0900f65bb08b7315';
