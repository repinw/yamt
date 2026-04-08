// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meals_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PreparedMealsController)
final preparedMealsControllerProvider = PreparedMealsControllerProvider._();

final class PreparedMealsControllerProvider
    extends
        $AsyncNotifierProvider<PreparedMealsController, List<PreparedMeal>> {
  PreparedMealsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preparedMealsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preparedMealsControllerHash();

  @$internal
  @override
  PreparedMealsController create() => PreparedMealsController();
}

String _$preparedMealsControllerHash() =>
    r'20f36462208c4059250ce7271cb723ad615d7181';

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
