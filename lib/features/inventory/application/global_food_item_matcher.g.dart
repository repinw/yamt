// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_food_item_matcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Global food item matcher.

@ProviderFor(globalFoodItemMatcher)
final globalFoodItemMatcherProvider = GlobalFoodItemMatcherProvider._();

/// Global food item matcher.

final class GlobalFoodItemMatcherProvider
    extends
        $FunctionalProvider<
          GlobalFoodItemMatcher,
          GlobalFoodItemMatcher,
          GlobalFoodItemMatcher
        >
    with $Provider<GlobalFoodItemMatcher> {
  /// Global food item matcher.
  GlobalFoodItemMatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalFoodItemMatcherProvider',
        isAutoDispose: true,
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
    r'6775f0a907e73d16eb674ec5a4869797953269d5';
