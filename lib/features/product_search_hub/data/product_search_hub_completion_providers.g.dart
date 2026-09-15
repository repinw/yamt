// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_search_hub_completion_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the completion handler for the given [mode].

@ProviderFor(productSearchHubCompletionHandler)
final productSearchHubCompletionHandlerProvider =
    ProductSearchHubCompletionHandlerFamily._();

/// Provides the completion handler for the given [mode].

final class ProductSearchHubCompletionHandlerProvider
    extends
        $FunctionalProvider<
          ProductSearchHubCompletionHandler,
          ProductSearchHubCompletionHandler,
          ProductSearchHubCompletionHandler
        >
    with $Provider<ProductSearchHubCompletionHandler> {
  /// Provides the completion handler for the given [mode].
  ProductSearchHubCompletionHandlerProvider._({
    required ProductSearchHubCompletionHandlerFamily super.from,
    required ProductSearchHubMode super.argument,
  }) : super(
         retry: null,
         name: r'productSearchHubCompletionHandlerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = inventoryItemsControllerProvider;
  static final $allTransitiveDependencies1 =
      InventoryItemsControllerProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      InventoryItemsControllerProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 =
      InventoryItemsControllerProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies4 =
      inventoryBackedCalorieEntrySaveFlowProvider;

  @override
  String debugGetCreateSourceHash() =>
      _$productSearchHubCompletionHandlerHash();

  @override
  String toString() {
    return r'productSearchHubCompletionHandlerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ProductSearchHubCompletionHandler> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductSearchHubCompletionHandler create(Ref ref) {
    final argument = this.argument as ProductSearchHubMode;
    return productSearchHubCompletionHandler(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductSearchHubCompletionHandler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductSearchHubCompletionHandler>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProductSearchHubCompletionHandlerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productSearchHubCompletionHandlerHash() =>
    r'11b67ec8877c0429bea3689e11b447c6d9bec236';

/// Provides the completion handler for the given [mode].

final class ProductSearchHubCompletionHandlerFamily extends $Family
    with
        $FunctionalFamilyOverride<
          ProductSearchHubCompletionHandler,
          ProductSearchHubMode
        > {
  ProductSearchHubCompletionHandlerFamily._()
    : super(
        retry: null,
        name: r'productSearchHubCompletionHandlerProvider',
        dependencies: <ProviderOrFamily>[
          inventoryItemsControllerProvider,
          inventoryBackedCalorieEntrySaveFlowProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          ProductSearchHubCompletionHandlerProvider.$allTransitiveDependencies0,
          ProductSearchHubCompletionHandlerProvider.$allTransitiveDependencies1,
          ProductSearchHubCompletionHandlerProvider.$allTransitiveDependencies2,
          ProductSearchHubCompletionHandlerProvider.$allTransitiveDependencies3,
          ProductSearchHubCompletionHandlerProvider.$allTransitiveDependencies4,
        },
        isAutoDispose: true,
      );

  /// Provides the completion handler for the given [mode].

  ProductSearchHubCompletionHandlerProvider call(ProductSearchHubMode mode) =>
      ProductSearchHubCompletionHandlerProvider._(argument: mode, from: this);

  @override
  String toString() => r'productSearchHubCompletionHandlerProvider';
}
