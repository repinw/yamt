// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_plan_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Accepts and deletes plans in the diary, and undoes both.
///
/// Kept alive, so it remembers the plans it ate until the diary reloads.

@ProviderFor(DiaryPlanController)
final diaryPlanControllerProvider = DiaryPlanControllerProvider._();

/// Accepts and deletes plans in the diary, and undoes both.
///
/// Kept alive, so it remembers the plans it ate until the diary reloads.
final class DiaryPlanControllerProvider
    extends $AsyncNotifierProvider<DiaryPlanController, void> {
  /// Accepts and deletes plans in the diary, and undoes both.
  ///
  /// Kept alive, so it remembers the plans it ate until the diary reloads.
  DiaryPlanControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryPlanControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryPlanControllerHash();

  @$internal
  @override
  DiaryPlanController create() => DiaryPlanController();
}

String _$diaryPlanControllerHash() =>
    r'39e259d57a6534b8342c2e796e1e0419578d60f6';

/// Accepts and deletes plans in the diary, and undoes both.
///
/// Kept alive, so it remembers the plans it ate until the diary reloads.

abstract class _$DiaryPlanController extends $AsyncNotifier<void> {
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
