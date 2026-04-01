// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_image_picker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(preparedMealImagePicker)
final preparedMealImagePickerProvider = PreparedMealImagePickerProvider._();

final class PreparedMealImagePickerProvider
    extends
        $FunctionalProvider<
          PreparedMealImagePicker,
          PreparedMealImagePicker,
          PreparedMealImagePicker
        >
    with $Provider<PreparedMealImagePicker> {
  PreparedMealImagePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preparedMealImagePickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preparedMealImagePickerHash();

  @$internal
  @override
  $ProviderElement<PreparedMealImagePicker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PreparedMealImagePicker create(Ref ref) {
    return preparedMealImagePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreparedMealImagePicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreparedMealImagePicker>(value),
    );
  }
}

String _$preparedMealImagePickerHash() =>
    r'e42c0d5f7528c5727d0924bf8914ed84fdb1c1dc';
