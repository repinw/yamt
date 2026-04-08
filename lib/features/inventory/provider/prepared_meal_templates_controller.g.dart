// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_templates_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PreparedMealTemplatesController)
final preparedMealTemplatesControllerProvider =
    PreparedMealTemplatesControllerProvider._();

final class PreparedMealTemplatesControllerProvider
    extends
        $AsyncNotifierProvider<
          PreparedMealTemplatesController,
          List<PreparedMeal>
        > {
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
    r'7db025cef07f611ef1b292acd268a372e6eadcdf';

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
