// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_label_ocr_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Nutrition label OCR repository.

@ProviderFor(nutritionLabelOcrRepository)
final nutritionLabelOcrRepositoryProvider =
    NutritionLabelOcrRepositoryProvider._();

/// Nutrition label OCR repository.

final class NutritionLabelOcrRepositoryProvider
    extends
        $FunctionalProvider<
          NutritionLabelOcrRepository,
          NutritionLabelOcrRepository,
          NutritionLabelOcrRepository
        >
    with $Provider<NutritionLabelOcrRepository> {
  /// Nutrition label OCR repository.
  NutritionLabelOcrRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nutritionLabelOcrRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nutritionLabelOcrRepositoryHash();

  @$internal
  @override
  $ProviderElement<NutritionLabelOcrRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NutritionLabelOcrRepository create(Ref ref) {
    return nutritionLabelOcrRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NutritionLabelOcrRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NutritionLabelOcrRepository>(value),
    );
  }
}

String _$nutritionLabelOcrRepositoryHash() =>
    r'5f57b04985afdce379d8a2837525ab8ebbc1cabb';

/// Nutrition label image picker.

@ProviderFor(nutritionLabelImagePicker)
final nutritionLabelImagePickerProvider = NutritionLabelImagePickerProvider._();

/// Nutrition label image picker.

final class NutritionLabelImagePickerProvider
    extends $FunctionalProvider<ImagePicker, ImagePicker, ImagePicker>
    with $Provider<ImagePicker> {
  /// Nutrition label image picker.
  NutritionLabelImagePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nutritionLabelImagePickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nutritionLabelImagePickerHash();

  @$internal
  @override
  $ProviderElement<ImagePicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImagePicker create(Ref ref) {
    return nutritionLabelImagePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImagePicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImagePicker>(value),
    );
  }
}

String _$nutritionLabelImagePickerHash() =>
    r'959ccd0682ea9c49537835b2e03976a332951d67';

/// Nutrition label template model client.

@ProviderFor(nutritionLabelTemplateModelClient)
final nutritionLabelTemplateModelClientProvider =
    NutritionLabelTemplateModelClientProvider._();

/// Nutrition label template model client.

final class NutritionLabelTemplateModelClientProvider
    extends
        $FunctionalProvider<
          NutritionLabelTemplateModelClient,
          NutritionLabelTemplateModelClient,
          NutritionLabelTemplateModelClient
        >
    with $Provider<NutritionLabelTemplateModelClient> {
  /// Nutrition label template model client.
  NutritionLabelTemplateModelClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nutritionLabelTemplateModelClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$nutritionLabelTemplateModelClientHash();

  @$internal
  @override
  $ProviderElement<NutritionLabelTemplateModelClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NutritionLabelTemplateModelClient create(Ref ref) {
    return nutritionLabelTemplateModelClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NutritionLabelTemplateModelClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NutritionLabelTemplateModelClient>(
        value,
      ),
    );
  }
}

String _$nutritionLabelTemplateModelClientHash() =>
    r'c5bf9635136fc133f552e0fb2d4842921aff44f0';
