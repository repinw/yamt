// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_recipe_importer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The prepared meal recipe importer provider.

@ProviderFor(preparedMealRecipeImporter)
final preparedMealRecipeImporterProvider =
    PreparedMealRecipeImporterProvider._();

/// The prepared meal recipe importer provider.

final class PreparedMealRecipeImporterProvider
    extends
        $FunctionalProvider<
          PreparedMealRecipeImporter,
          PreparedMealRecipeImporter,
          PreparedMealRecipeImporter
        >
    with $Provider<PreparedMealRecipeImporter> {
  /// The prepared meal recipe importer provider.
  PreparedMealRecipeImporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preparedMealRecipeImporterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preparedMealRecipeImporterHash();

  @$internal
  @override
  $ProviderElement<PreparedMealRecipeImporter> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PreparedMealRecipeImporter create(Ref ref) {
    return preparedMealRecipeImporter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreparedMealRecipeImporter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreparedMealRecipeImporter>(value),
    );
  }
}

String _$preparedMealRecipeImporterHash() =>
    r'4b85bc1279b4a56634705deff7e319c909562862';
