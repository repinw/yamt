// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_image_picker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Prepared meal image picker.

@ProviderFor(preparedMealImagePicker)
final preparedMealImagePickerProvider = PreparedMealImagePickerProvider._();

/// Prepared meal image picker.

final class PreparedMealImagePickerProvider
    extends
        $FunctionalProvider<
          PreparedMealImagePicker,
          PreparedMealImagePicker,
          PreparedMealImagePicker
        >
    with $Provider<PreparedMealImagePicker> {
  /// Prepared meal image picker.
  PreparedMealImagePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preparedMealImagePickerProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
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
    r'0bcc751df47c7afcbb6664dc89f402223a581e75';
