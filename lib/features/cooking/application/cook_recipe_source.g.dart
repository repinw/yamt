// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_recipe_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Kochbuch recipe `recipeId` as stored today, read only, or `null`
/// when it is gone or a Vorlage. Until the recipes move to their own
/// collection, cooking reads them from the cookbook templates.

@ProviderFor(cookRecipeTemplate)
final cookRecipeTemplateProvider = CookRecipeTemplateFamily._();

/// The Kochbuch recipe `recipeId` as stored today, read only, or `null`
/// when it is gone or a Vorlage. Until the recipes move to their own
/// collection, cooking reads them from the cookbook templates.

final class CookRecipeTemplateProvider
    extends
        $FunctionalProvider<
          AsyncValue<PreparedMeal?>,
          PreparedMeal?,
          Stream<PreparedMeal?>
        >
    with $FutureModifier<PreparedMeal?>, $StreamProvider<PreparedMeal?> {
  /// The Kochbuch recipe `recipeId` as stored today, read only, or `null`
  /// when it is gone or a Vorlage. Until the recipes move to their own
  /// collection, cooking reads them from the cookbook templates.
  CookRecipeTemplateProvider._({
    required CookRecipeTemplateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cookRecipeTemplateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cookRecipeTemplateHash();

  @override
  String toString() {
    return r'cookRecipeTemplateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<PreparedMeal?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<PreparedMeal?> create(Ref ref) {
    final argument = this.argument as String;
    return cookRecipeTemplate(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CookRecipeTemplateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cookRecipeTemplateHash() =>
    r'3136a9128cdf0cd9b2b4dcaf4b4623de1f04efd0';

/// The Kochbuch recipe `recipeId` as stored today, read only, or `null`
/// when it is gone or a Vorlage. Until the recipes move to their own
/// collection, cooking reads them from the cookbook templates.

final class CookRecipeTemplateFamily extends $Family
    with $FunctionalFamilyOverride<Stream<PreparedMeal?>, String> {
  CookRecipeTemplateFamily._()
    : super(
        retry: null,
        name: r'cookRecipeTemplateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The Kochbuch recipe `recipeId` as stored today, read only, or `null`
  /// when it is gone or a Vorlage. Until the recipes move to their own
  /// collection, cooking reads them from the cookbook templates.

  CookRecipeTemplateProvider call(String recipeId) =>
      CookRecipeTemplateProvider._(argument: recipeId, from: this);

  @override
  String toString() => r'cookRecipeTemplateProvider';
}
