// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_page_action_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Handles calorie page actions that need providers.

@ProviderFor(CaloriePageActionController)
final caloriePageActionControllerProvider =
    CaloriePageActionControllerProvider._();

/// Handles calorie page actions that need providers.
final class CaloriePageActionControllerProvider
    extends $AsyncNotifierProvider<CaloriePageActionController, void> {
  /// Handles calorie page actions that need providers.
  CaloriePageActionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'caloriePageActionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$caloriePageActionControllerHash();

  @$internal
  @override
  CaloriePageActionController create() => CaloriePageActionController();
}

String _$caloriePageActionControllerHash() =>
    r'8fd3fc67017834c3580322f149855391323adece';

/// Handles calorie page actions that need providers.

abstract class _$CaloriePageActionController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
