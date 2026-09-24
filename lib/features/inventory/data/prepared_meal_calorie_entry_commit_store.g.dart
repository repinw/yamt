// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_calorie_entry_commit_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The prepared meal calorie entry commit store provider.

@ProviderFor(preparedMealCalorieEntryCommitStore)
final preparedMealCalorieEntryCommitStoreProvider =
    PreparedMealCalorieEntryCommitStoreProvider._();

/// The prepared meal calorie entry commit store provider.

final class PreparedMealCalorieEntryCommitStoreProvider
    extends
        $FunctionalProvider<
          PreparedMealCalorieEntryCommitStore?,
          PreparedMealCalorieEntryCommitStore?,
          PreparedMealCalorieEntryCommitStore?
        >
    with $Provider<PreparedMealCalorieEntryCommitStore?> {
  /// The prepared meal calorie entry commit store provider.
  PreparedMealCalorieEntryCommitStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preparedMealCalorieEntryCommitStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$preparedMealCalorieEntryCommitStoreHash();

  @$internal
  @override
  $ProviderElement<PreparedMealCalorieEntryCommitStore?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PreparedMealCalorieEntryCommitStore? create(Ref ref) {
    return preparedMealCalorieEntryCommitStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreparedMealCalorieEntryCommitStore? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<PreparedMealCalorieEntryCommitStore?>(value),
    );
  }
}

String _$preparedMealCalorieEntryCommitStoreHash() =>
    r'7b9bb95fc70fb93257760fe786d7f964b33e8662';
