// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_meal_preview.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The nutrients of the whole meal that [portioning] would put into the
/// Vorrat now. It fails like "In Vorrat" would, for example when a food
/// lacks nutrition.

@ProviderFor(cookMealPreview)
final cookMealPreviewProvider = CookMealPreviewFamily._();

/// The nutrients of the whole meal that [portioning] would put into the
/// Vorrat now. It fails like "In Vorrat" would, for example when a food
/// lacks nutrition.

final class CookMealPreviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<EatMealNutrition>,
          AsyncValue<EatMealNutrition>,
          AsyncValue<EatMealNutrition>
        >
    with $Provider<AsyncValue<EatMealNutrition>> {
  /// The nutrients of the whole meal that [portioning] would put into the
  /// Vorrat now. It fails like "In Vorrat" would, for example when a food
  /// lacks nutrition.
  CookMealPreviewProvider._({
    required CookMealPreviewFamily super.from,
    required (String, String, CookPortioning) super.argument,
  }) : super(
         retry: null,
         name: r'cookMealPreviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cookMealPreviewHash();

  @override
  String toString() {
    return r'cookMealPreviewProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<EatMealNutrition>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<EatMealNutrition> create(Ref ref) {
    final argument = this.argument as (String, String, CookPortioning);
    return cookMealPreview(ref, argument.$1, argument.$2, argument.$3);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<EatMealNutrition> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<EatMealNutrition>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CookMealPreviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cookMealPreviewHash() => r'25dc0169456b5215e689d75da0a4295a101a1f23';

/// The nutrients of the whole meal that [portioning] would put into the
/// Vorrat now. It fails like "In Vorrat" would, for example when a food
/// lacks nutrition.

final class CookMealPreviewFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<EatMealNutrition>,
          (String, String, CookPortioning)
        > {
  CookMealPreviewFamily._()
    : super(
        retry: null,
        name: r'cookMealPreviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The nutrients of the whole meal that [portioning] would put into the
  /// Vorrat now. It fails like "In Vorrat" would, for example when a food
  /// lacks nutrition.

  CookMealPreviewProvider call(
    String recipeId,
    String localeCode,
    CookPortioning portioning,
  ) => CookMealPreviewProvider._(
    argument: (recipeId, localeCode, portioning),
    from: this,
  );

  @override
  String toString() => r'cookMealPreviewProvider';
}
