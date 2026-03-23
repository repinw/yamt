// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_food_item_matcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(globalFoodItemMatcher)
final globalFoodItemMatcherProvider = GlobalFoodItemMatcherProvider._();

final class GlobalFoodItemMatcherProvider
    extends
        $FunctionalProvider<
          GlobalFoodItemMatcher,
          GlobalFoodItemMatcher,
          GlobalFoodItemMatcher
        >
    with $Provider<GlobalFoodItemMatcher> {
  GlobalFoodItemMatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalFoodItemMatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalFoodItemMatcherHash();

  @$internal
  @override
  $ProviderElement<GlobalFoodItemMatcher> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GlobalFoodItemMatcher create(Ref ref) {
    return globalFoodItemMatcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobalFoodItemMatcher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlobalFoodItemMatcher>(value),
    );
  }
}

String _$globalFoodItemMatcherHash() =>
    r'47a496ea2ffb13cad77e541c5f1f8aecf0f86d4b';
