// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_guide_view.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Kochhelfer for the recipe [recipeId] as the recipe page cooks it:
/// with its portions and the cook's changes. `null` when the recipe is
/// gone.

@ProviderFor(cookingGuide)
final cookingGuideProvider = CookingGuideFamily._();

/// The Kochhelfer for the recipe [recipeId] as the recipe page cooks it:
/// with its portions and the cook's changes. `null` when the recipe is
/// gone.

final class CookingGuideProvider
    extends
        $FunctionalProvider<
          AsyncValue<CookingGuide?>,
          AsyncValue<CookingGuide?>,
          AsyncValue<CookingGuide?>
        >
    with $Provider<AsyncValue<CookingGuide?>> {
  /// The Kochhelfer for the recipe [recipeId] as the recipe page cooks it:
  /// with its portions and the cook's changes. `null` when the recipe is
  /// gone.
  CookingGuideProvider._({
    required CookingGuideFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'cookingGuideProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cookingGuideHash();

  @override
  String toString() {
    return r'cookingGuideProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<CookingGuide?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<CookingGuide?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return cookingGuide(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<CookingGuide?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<CookingGuide?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CookingGuideProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cookingGuideHash() => r'2c5bdef2f6b75f75f659e7ae2af9d5f77df66f47';

/// The Kochhelfer for the recipe [recipeId] as the recipe page cooks it:
/// with its portions and the cook's changes. `null` when the recipe is
/// gone.

final class CookingGuideFamily extends $Family
    with
        $FunctionalFamilyOverride<AsyncValue<CookingGuide?>, (String, String)> {
  CookingGuideFamily._()
    : super(
        retry: null,
        name: r'cookingGuideProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The Kochhelfer for the recipe [recipeId] as the recipe page cooks it:
  /// with its portions and the cook's changes. `null` when the recipe is
  /// gone.

  CookingGuideProvider call(String recipeId, String localeCode) =>
      CookingGuideProvider._(argument: (recipeId, localeCode), from: this);

  @override
  String toString() => r'cookingGuideProvider';
}
