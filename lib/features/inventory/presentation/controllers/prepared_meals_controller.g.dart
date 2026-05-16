// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meals_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Defines prepared meals controller.

@ProviderFor(PreparedMealsController)
final preparedMealsControllerProvider = PreparedMealsControllerProvider._();

/// Defines prepared meals controller.
final class PreparedMealsControllerProvider
    extends
        $AsyncNotifierProvider<PreparedMealsController, List<PreparedMeal>> {
  /// Defines prepared meals controller.
  PreparedMealsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preparedMealsControllerProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          inventoryActivityEventRepositoryProvider,
          inventoryDiscardEventRepositoryProvider,
          inventoryItemRepositoryProvider,
          preparedMealCalorieLogBridgeProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          PreparedMealsControllerProvider.$allTransitiveDependencies0,
          PreparedMealsControllerProvider.$allTransitiveDependencies1,
          PreparedMealsControllerProvider.$allTransitiveDependencies2,
          PreparedMealsControllerProvider.$allTransitiveDependencies3,
          PreparedMealsControllerProvider.$allTransitiveDependencies4,
        },
      );

  static final $allTransitiveDependencies0 =
      inventoryActivityEventRepositoryProvider;
  static final $allTransitiveDependencies1 =
      inventoryDiscardEventRepositoryProvider;
  static final $allTransitiveDependencies2 = inventoryItemRepositoryProvider;
  static final $allTransitiveDependencies3 =
      preparedMealCalorieLogBridgeProvider;
  static final $allTransitiveDependencies4 =
      PreparedMealCalorieLogBridgeProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$preparedMealsControllerHash();

  @$internal
  @override
  PreparedMealsController create() => PreparedMealsController();
}

String _$preparedMealsControllerHash() =>
    r'118809918c80901a2df501c88bb745fe7821fe14';

/// Defines prepared meals controller.

abstract class _$PreparedMealsController
    extends $AsyncNotifier<List<PreparedMeal>> {
  FutureOr<List<PreparedMeal>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PreparedMeal>>, List<PreparedMeal>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PreparedMeal>>, List<PreparedMeal>>,
              AsyncValue<List<PreparedMeal>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
