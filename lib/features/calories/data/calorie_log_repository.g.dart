// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_log_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calorie log repository.

@ProviderFor(calorieLogRepository)
final calorieLogRepositoryProvider = CalorieLogRepositoryProvider._();

/// Calorie log repository.

final class CalorieLogRepositoryProvider
    extends
        $FunctionalProvider<
          CalorieLogRepositoryContract,
          CalorieLogRepositoryContract,
          CalorieLogRepositoryContract
        >
    with $Provider<CalorieLogRepositoryContract> {
  /// Calorie log repository.
  CalorieLogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieLogRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieLogRepositoryHash();

  @$internal
  @override
  $ProviderElement<CalorieLogRepositoryContract> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieLogRepositoryContract create(Ref ref) {
    return calorieLogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieLogRepositoryContract value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieLogRepositoryContract>(value),
    );
  }
}

String _$calorieLogRepositoryHash() =>
    r'3661b7e9bbfd856e751fc4b5fc6fbda0e7c67142';
