// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_suggestion_views.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The [suggestions] the strip shows: without the products still to buy on
/// the list shown, the pushed back ones behind all others.

@ProviderFor(shoppingVisibleSuggestions)
final shoppingVisibleSuggestionsProvider = ShoppingVisibleSuggestionsFamily._();

/// The [suggestions] the strip shows: without the products still to buy on
/// the list shown, the pushed back ones behind all others.

final class ShoppingVisibleSuggestionsProvider
    extends
        $FunctionalProvider<
          List<ShoppingSuggestion>,
          List<ShoppingSuggestion>,
          List<ShoppingSuggestion>
        >
    with $Provider<List<ShoppingSuggestion>> {
  /// The [suggestions] the strip shows: without the products still to buy on
  /// the list shown, the pushed back ones behind all others.
  ShoppingVisibleSuggestionsProvider._({
    required ShoppingVisibleSuggestionsFamily super.from,
    required ShoppingSuggestionList super.argument,
  }) : super(
         retry: null,
         name: r'shoppingVisibleSuggestionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shoppingVisibleSuggestionsHash();

  @override
  String toString() {
    return r'shoppingVisibleSuggestionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<ShoppingSuggestion>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ShoppingSuggestion> create(Ref ref) {
    final argument = this.argument as ShoppingSuggestionList;
    return shoppingVisibleSuggestions(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ShoppingSuggestion> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ShoppingSuggestion>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ShoppingVisibleSuggestionsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shoppingVisibleSuggestionsHash() =>
    r'c96b820eebf5f1c9e3dc5c8a48cb6ed10c823a1e';

/// The [suggestions] the strip shows: without the products still to buy on
/// the list shown, the pushed back ones behind all others.

final class ShoppingVisibleSuggestionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          List<ShoppingSuggestion>,
          ShoppingSuggestionList
        > {
  ShoppingVisibleSuggestionsFamily._()
    : super(
        retry: null,
        name: r'shoppingVisibleSuggestionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The [suggestions] the strip shows: without the products still to buy on
  /// the list shown, the pushed back ones behind all others.

  ShoppingVisibleSuggestionsProvider call(ShoppingSuggestionList suggestions) =>
      ShoppingVisibleSuggestionsProvider._(argument: suggestions, from: this);

  @override
  String toString() => r'shoppingVisibleSuggestionsProvider';
}

/// What the add sheet offers for the typed [text], in the catalog of
/// [languageCode], matched against the list the addition goes to.

@ProviderFor(shoppingAddOfferFor)
final shoppingAddOfferForProvider = ShoppingAddOfferForFamily._();

/// What the add sheet offers for the typed [text], in the catalog of
/// [languageCode], matched against the list the addition goes to.

final class ShoppingAddOfferForProvider
    extends
        $FunctionalProvider<
          ShoppingAddOffer,
          ShoppingAddOffer,
          ShoppingAddOffer
        >
    with $Provider<ShoppingAddOffer> {
  /// What the add sheet offers for the typed [text], in the catalog of
  /// [languageCode], matched against the list the addition goes to.
  ShoppingAddOfferForProvider._({
    required ShoppingAddOfferForFamily super.from,
    required ({
      String text,
      String languageCode,
      ShoppingSuggestionList suggestions,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'shoppingAddOfferForProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shoppingAddOfferForHash();

  @override
  String toString() {
    return r'shoppingAddOfferForProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<ShoppingAddOffer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ShoppingAddOffer create(Ref ref) {
    final argument =
        this.argument
            as ({
              String text,
              String languageCode,
              ShoppingSuggestionList suggestions,
            });
    return shoppingAddOfferFor(
      ref,
      text: argument.text,
      languageCode: argument.languageCode,
      suggestions: argument.suggestions,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShoppingAddOffer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShoppingAddOffer>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ShoppingAddOfferForProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shoppingAddOfferForHash() =>
    r'7b0ec27bc240668243ecb95a8ba1282999b07583';

/// What the add sheet offers for the typed [text], in the catalog of
/// [languageCode], matched against the list the addition goes to.

final class ShoppingAddOfferForFamily extends $Family
    with
        $FunctionalFamilyOverride<
          ShoppingAddOffer,
          ({
            String text,
            String languageCode,
            ShoppingSuggestionList suggestions,
          })
        > {
  ShoppingAddOfferForFamily._()
    : super(
        retry: null,
        name: r'shoppingAddOfferForProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// What the add sheet offers for the typed [text], in the catalog of
  /// [languageCode], matched against the list the addition goes to.

  ShoppingAddOfferForProvider call({
    required String text,
    required String languageCode,
    required ShoppingSuggestionList suggestions,
  }) => ShoppingAddOfferForProvider._(
    argument: (
      text: text,
      languageCode: languageCode,
      suggestions: suggestions,
    ),
    from: this,
  );

  @override
  String toString() => r'shoppingAddOfferForProvider';
}
