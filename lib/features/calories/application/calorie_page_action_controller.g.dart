// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_page_action_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Handles calorie page actions that need providers.
///
/// Diary callbacks capture this notifier without watching it, so it lives
/// for the whole session.

@ProviderFor(CaloriePageActionController)
final caloriePageActionControllerProvider =
    CaloriePageActionControllerProvider._();

/// Handles calorie page actions that need providers.
///
/// Diary callbacks capture this notifier without watching it, so it lives
/// for the whole session.
final class CaloriePageActionControllerProvider
    extends $AsyncNotifierProvider<CaloriePageActionController, void> {
  /// Handles calorie page actions that need providers.
  ///
  /// Diary callbacks capture this notifier without watching it, so it lives
  /// for the whole session.
  CaloriePageActionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'caloriePageActionControllerProvider',
        isAutoDispose: false,
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
    r'ae86f36a00752b3ca4562091cacc771e287f2043';

/// Handles calorie page actions that need providers.
///
/// Diary callbacks capture this notifier without watching it, so it lives
/// for the whole session.

abstract class _$CaloriePageActionController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
