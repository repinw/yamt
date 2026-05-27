// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_debug_action_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Handles calorie debug actions that need providers.

@ProviderFor(CalorieDebugActionController)
final calorieDebugActionControllerProvider =
    CalorieDebugActionControllerProvider._();

/// Handles calorie debug actions that need providers.
final class CalorieDebugActionControllerProvider
    extends $AsyncNotifierProvider<CalorieDebugActionController, void> {
  /// Handles calorie debug actions that need providers.
  CalorieDebugActionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieDebugActionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieDebugActionControllerHash();

  @$internal
  @override
  CalorieDebugActionController create() => CalorieDebugActionController();
}

String _$calorieDebugActionControllerHash() =>
    r'4c39f3b67e7a938d7ac22ebc3a98247d49b46fdd';

/// Handles calorie debug actions that need providers.

abstract class _$CalorieDebugActionController extends $AsyncNotifier<void> {
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
