// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_entry_delete_flow.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The calorie entry delete flow provider.

@ProviderFor(calorieEntryDeleteFlow)
final calorieEntryDeleteFlowProvider = CalorieEntryDeleteFlowProvider._();

/// The calorie entry delete flow provider.

final class CalorieEntryDeleteFlowProvider
    extends
        $FunctionalProvider<
          CalorieEntryDeleteFlow,
          CalorieEntryDeleteFlow,
          CalorieEntryDeleteFlow
        >
    with $Provider<CalorieEntryDeleteFlow> {
  /// The calorie entry delete flow provider.
  CalorieEntryDeleteFlowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieEntryDeleteFlowProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          inventoryItemRepositoryProvider,
          inventoryItemsControllerProvider,
          preparedMealsControllerProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          CalorieEntryDeleteFlowProvider.$allTransitiveDependencies0,
          CalorieEntryDeleteFlowProvider.$allTransitiveDependencies1,
          CalorieEntryDeleteFlowProvider.$allTransitiveDependencies2,
        ],
      );

  static final $allTransitiveDependencies0 = inventoryItemRepositoryProvider;
  static final $allTransitiveDependencies1 = inventoryItemsControllerProvider;
  static final $allTransitiveDependencies2 = preparedMealsControllerProvider;

  @override
  String debugGetCreateSourceHash() => _$calorieEntryDeleteFlowHash();

  @$internal
  @override
  $ProviderElement<CalorieEntryDeleteFlow> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieEntryDeleteFlow create(Ref ref) {
    return calorieEntryDeleteFlow(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieEntryDeleteFlow value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieEntryDeleteFlow>(value),
    );
  }
}

String _$calorieEntryDeleteFlowHash() =>
    r'a93421419e60cc975d676c80f72881a35d6c7890';
