// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_body_edit_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the body edit service for the current calorie settings.

@ProviderFor(calorieBodyEditService)
final calorieBodyEditServiceProvider = CalorieBodyEditServiceProvider._();

/// Provides the body edit service for the current calorie settings.

final class CalorieBodyEditServiceProvider
    extends
        $FunctionalProvider<
          CalorieBodyEditService,
          CalorieBodyEditService,
          CalorieBodyEditService
        >
    with $Provider<CalorieBodyEditService> {
  /// Provides the body edit service for the current calorie settings.
  CalorieBodyEditServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieBodyEditServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieBodyEditServiceHash();

  @$internal
  @override
  $ProviderElement<CalorieBodyEditService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieBodyEditService create(Ref ref) {
    return calorieBodyEditService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieBodyEditService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieBodyEditService>(value),
    );
  }
}

String _$calorieBodyEditServiceHash() =>
    r'7be74908e5c448572ce72f0c79837e9386a96eee';
