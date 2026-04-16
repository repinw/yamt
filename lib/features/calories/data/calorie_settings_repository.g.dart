// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_settings_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calorie settings repository.

@ProviderFor(calorieSettingsRepository)
final calorieSettingsRepositoryProvider = CalorieSettingsRepositoryProvider._();

/// Calorie settings repository.

final class CalorieSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          CalorieSettingsRepository,
          CalorieSettingsRepository,
          CalorieSettingsRepository
        >
    with $Provider<CalorieSettingsRepository> {
  /// Calorie settings repository.
  CalorieSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieSettingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieSettingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<CalorieSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieSettingsRepository create(Ref ref) {
    return calorieSettingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieSettingsRepository>(value),
    );
  }
}

String _$calorieSettingsRepositoryHash() =>
    r'e13ca88ed5f3917d1666c8f142c62e3a43be967c';
