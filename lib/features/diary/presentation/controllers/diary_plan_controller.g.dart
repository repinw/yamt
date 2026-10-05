// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_plan_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Deletes plans from the diary and brings them back on undo.

@ProviderFor(DiaryPlanController)
final diaryPlanControllerProvider = DiaryPlanControllerProvider._();

/// Deletes plans from the diary and brings them back on undo.
final class DiaryPlanControllerProvider
    extends $AsyncNotifierProvider<DiaryPlanController, void> {
  /// Deletes plans from the diary and brings them back on undo.
  DiaryPlanControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryPlanControllerProvider',
        isAutoDispose: true,
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
    r'18dc3e7040bb23e9081daf47188fb1df27fc119b';

/// Deletes plans from the diary and brings them back on undo.

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
