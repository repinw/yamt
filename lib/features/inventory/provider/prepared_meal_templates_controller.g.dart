// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_templates_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Defines prepared meal templates controller.

@ProviderFor(PreparedMealTemplatesController)
final preparedMealTemplatesControllerProvider =
    PreparedMealTemplatesControllerProvider._();

/// Defines prepared meal templates controller.
final class PreparedMealTemplatesControllerProvider
    extends
        $AsyncNotifierProvider<
          PreparedMealTemplatesController,
          List<PreparedMeal>
        > {
  /// Defines prepared meal templates controller.
  PreparedMealTemplatesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preparedMealTemplatesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preparedMealTemplatesControllerHash();

  @$internal
  @override
  PreparedMealTemplatesController create() => PreparedMealTemplatesController();
}

String _$preparedMealTemplatesControllerHash() =>
    r'fd8548fb54949cf4125fec74fa500bc0d7777f28';

/// Defines prepared meal templates controller.

abstract class _$PreparedMealTemplatesController
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
