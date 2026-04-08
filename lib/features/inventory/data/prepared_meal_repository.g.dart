// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(preparedMealRepository)
final preparedMealRepositoryProvider = PreparedMealRepositoryProvider._();

final class PreparedMealRepositoryProvider
    extends
        $FunctionalProvider<
          PreparedMealRepository,
          PreparedMealRepository,
          PreparedMealRepository
        >
    with $Provider<PreparedMealRepository> {
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
    r'e706b0b8871415a211725313ab719ceb73b115bc';
