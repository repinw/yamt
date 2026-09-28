// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Prepared meal repository.

@ProviderFor(preparedMealRepository)
final preparedMealRepositoryProvider = PreparedMealRepositoryProvider._();

/// Prepared meal repository.

final class PreparedMealRepositoryProvider
    extends
        $FunctionalProvider<
          PreparedMealRepository,
          PreparedMealRepository,
          PreparedMealRepository
        >
    with $Provider<PreparedMealRepository> {
  /// Prepared meal repository.
  PreparedMealRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preparedMealRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preparedMealRepositoryHash();

  @$internal
  @override
  $ProviderElement<PreparedMealRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PreparedMealRepository create(Ref ref) {
    return preparedMealRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreparedMealRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreparedMealRepository>(value),
    );
  }
}

String _$preparedMealRepositoryHash() =>
    r'c111bc88d4956f166f55dac9fd6e94b7ec4375c0';
