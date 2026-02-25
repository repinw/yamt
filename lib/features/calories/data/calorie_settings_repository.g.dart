// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_settings_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(calorieSettingsRepository)
final calorieSettingsRepositoryProvider = CalorieSettingsRepositoryProvider._();

final class CalorieSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          CalorieSettingsRepository,
          CalorieSettingsRepository,
          CalorieSettingsRepository
        >
    with $Provider<CalorieSettingsRepository> {
  CalorieSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieSettingsRepositoryProvider',
        isAutoDispose: true,
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
    r'5ae47e0d3f40f26dfa2abef327f594f3ef1b64fe';
