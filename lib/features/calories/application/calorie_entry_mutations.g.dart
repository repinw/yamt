// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_entry_mutations.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared local mutation stream, owned by Calories rather than Diary UI.

@ProviderFor(calorieEntryMutations)
final calorieEntryMutationsProvider = CalorieEntryMutationsProvider._();

/// Shared local mutation stream, owned by Calories rather than Diary UI.

final class CalorieEntryMutationsProvider
    extends
        $FunctionalProvider<
          CalorieEntryMutations,
          CalorieEntryMutations,
          CalorieEntryMutations
        >
    with $Provider<CalorieEntryMutations> {
  /// Shared local mutation stream, owned by Calories rather than Diary UI.
  CalorieEntryMutationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieEntryMutationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieEntryMutationsHash();

  @$internal
  @override
  $ProviderElement<CalorieEntryMutations> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieEntryMutations create(Ref ref) {
    return calorieEntryMutations(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieEntryMutations value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieEntryMutations>(value),
    );
  }
}

String _$calorieEntryMutationsHash() =>
    r'7ae8249cac33aaf08c3edf8fbc2a1948270b4260';
