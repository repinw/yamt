// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_entry_deleter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides calorie-entry deletion without exposing the Calories controller.

@ProviderFor(calorieEntryDeleter)
final calorieEntryDeleterProvider = CalorieEntryDeleterProvider._();

/// Provides calorie-entry deletion without exposing the Calories controller.

final class CalorieEntryDeleterProvider
    extends
        $FunctionalProvider<
          CalorieEntryDeleter,
          CalorieEntryDeleter,
          CalorieEntryDeleter
        >
    with $Provider<CalorieEntryDeleter> {
  /// Provides calorie-entry deletion without exposing the Calories controller.
  CalorieEntryDeleterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieEntryDeleterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieEntryDeleterHash();

  @$internal
  @override
  $ProviderElement<CalorieEntryDeleter> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieEntryDeleter create(Ref ref) {
    return calorieEntryDeleter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieEntryDeleter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieEntryDeleter>(value),
    );
  }
}

String _$calorieEntryDeleterHash() =>
    r'0e9773721c780a244f4d1d50a98c7ce5bc11133f';
