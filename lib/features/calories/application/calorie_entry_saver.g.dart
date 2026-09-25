// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_entry_saver.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides calorie-entry persistence without exposing the Calories controller.

@ProviderFor(calorieEntrySaver)
final calorieEntrySaverProvider = CalorieEntrySaverProvider._();

/// Provides calorie-entry persistence without exposing the Calories controller.

final class CalorieEntrySaverProvider
    extends
        $FunctionalProvider<
          CalorieEntrySaver,
          CalorieEntrySaver,
          CalorieEntrySaver
        >
    with $Provider<CalorieEntrySaver> {
  /// Provides calorie-entry persistence without exposing the Calories controller.
  CalorieEntrySaverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieEntrySaverProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieEntrySaverHash();

  @$internal
  @override
  $ProviderElement<CalorieEntrySaver> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieEntrySaver create(Ref ref) {
    return calorieEntrySaver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieEntrySaver value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieEntrySaver>(value),
    );
  }
}

String _$calorieEntrySaverHash() => r'7e7b6c4f3e8d0b17b8b6a4ecad34f62c4182a130';
