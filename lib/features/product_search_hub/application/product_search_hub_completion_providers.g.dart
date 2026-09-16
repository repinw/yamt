// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_search_hub_completion_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the default no-op handler factory for standalone hub usage.

@ProviderFor(productSearchHubCompletionHandlerFactory)
final productSearchHubCompletionHandlerFactoryProvider =
    ProductSearchHubCompletionHandlerFactoryProvider._();

/// Provides the default no-op handler factory for standalone hub usage.

final class ProductSearchHubCompletionHandlerFactoryProvider
    extends
        $FunctionalProvider<
          ProductSearchHubCompletionHandlerFactory,
          ProductSearchHubCompletionHandlerFactory,
          ProductSearchHubCompletionHandlerFactory
        >
    with $Provider<ProductSearchHubCompletionHandlerFactory> {
  /// Provides the default no-op handler factory for standalone hub usage.
  ProductSearchHubCompletionHandlerFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productSearchHubCompletionHandlerFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$productSearchHubCompletionHandlerFactoryHash();

  @$internal
  @override
  $ProviderElement<ProductSearchHubCompletionHandlerFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductSearchHubCompletionHandlerFactory create(Ref ref) {
    return productSearchHubCompletionHandlerFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductSearchHubCompletionHandlerFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<ProductSearchHubCompletionHandlerFactory>(value),
    );
  }
}

String _$productSearchHubCompletionHandlerFactoryHash() =>
    r'53834aa2ab8d2989cab6bd7a1f2e36fa47e96ba2';

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
    r'c86388d4e205d5ffaadb2ac273331fab7fce423b';

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
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides the completion handler for the given [mode].

  ProductSearchHubCompletionHandlerProvider call(ProductSearchHubMode mode) =>
      ProductSearchHubCompletionHandlerProvider._(argument: mode, from: this);

  @override
  String toString() => r'productSearchHubCompletionHandlerProvider';
}
