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
        dependencies: <ProviderOrFamily>[inventoryItemRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          PreparedMealsControllerProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = inventoryItemRepositoryProvider;

  @override
  String debugGetCreateSourceHash() => _$preparedMealsControllerHash();

  @$internal
  @override
  PreparedMealsController create() => PreparedMealsController();
}

String _$preparedMealsControllerHash() =>
    r'79ea4bf8dd3a41ae80a9176c1b541c3978ec5519';

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
