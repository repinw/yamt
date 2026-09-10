// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_suggestions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Public injection point for recommendations from a data-owning feature.

@ProviderFor(shoppingSuggestionSource)
final shoppingSuggestionSourceProvider = ShoppingSuggestionSourceProvider._();

/// Public injection point for recommendations from a data-owning feature.

final class ShoppingSuggestionSourceProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ShoppingSuggestion>>,
          AsyncValue<List<ShoppingSuggestion>>,
          AsyncValue<List<ShoppingSuggestion>>
        >
    with $Provider<AsyncValue<List<ShoppingSuggestion>>> {
  /// Public injection point for recommendations from a data-owning feature.
  ShoppingSuggestionSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingSuggestionSourceProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingSuggestionSourceHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<ShoppingSuggestion>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<ShoppingSuggestion>> create(Ref ref) {
    return shoppingSuggestionSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<ShoppingSuggestion>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<List<ShoppingSuggestion>>>(value),
    );
  }
}

String _$shoppingSuggestionSourceHash() =>
    r'74613cb0ef99f117817f60e175bef45d9bc96b62';

/// Removes products already listed, independently of source loading.

@ProviderFor(shoppingSuggestions)
final shoppingSuggestionsProvider = ShoppingSuggestionsProvider._();

/// Removes products already listed, independently of source loading.

final class ShoppingSuggestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ShoppingSuggestion>>,
          AsyncValue<List<ShoppingSuggestion>>,
          AsyncValue<List<ShoppingSuggestion>>
        >
    with $Provider<AsyncValue<List<ShoppingSuggestion>>> {
  /// Removes products already listed, independently of source loading.
  ShoppingSuggestionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingSuggestionsProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[shoppingSuggestionSourceProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ShoppingSuggestionsProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = shoppingSuggestionSourceProvider;

  @override
  String debugGetCreateSourceHash() => _$shoppingSuggestionsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<ShoppingSuggestion>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<ShoppingSuggestion>> create(Ref ref) {
    return shoppingSuggestions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<ShoppingSuggestion>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<List<ShoppingSuggestion>>>(value),
    );
  }
}

String _$shoppingSuggestionsHash() =>
    r'7f4f95bf24ea8d887521e58c900cd053982d3cd2';

/// Public refresh callback supplied alongside the recommendation source.

@ProviderFor(shoppingSuggestionRetry)
final shoppingSuggestionRetryProvider = ShoppingSuggestionRetryProvider._();

/// Public refresh callback supplied alongside the recommendation source.

final class ShoppingSuggestionRetryProvider
    extends
        $FunctionalProvider<void Function(), void Function(), void Function()>
    with $Provider<void Function()> {
  /// Public refresh callback supplied alongside the recommendation source.
  ShoppingSuggestionRetryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingSuggestionRetryProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingSuggestionRetryHash();

  @$internal
  @override
  $ProviderElement<void Function()> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void Function() create(Ref ref) {
    return shoppingSuggestionRetry(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void Function()>(value),
    );
  }
}

String _$shoppingSuggestionRetryHash() =>
    r'46f57266d87ede9b01845994bb36b8b282de7e73';
