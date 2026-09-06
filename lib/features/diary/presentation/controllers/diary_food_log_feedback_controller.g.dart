// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_food_log_feedback_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Transient presentation queue; nothing is replayed after app restart.

@ProviderFor(DiaryFoodLogFeedbackController)
final diaryFoodLogFeedbackControllerProvider =
    DiaryFoodLogFeedbackControllerProvider._();

/// Transient presentation queue; nothing is replayed after app restart.
final class DiaryFoodLogFeedbackControllerProvider
    extends
        $NotifierProvider<
          DiaryFoodLogFeedbackController,
          List<DiaryFoodLogFeedback>
        > {
  /// Transient presentation queue; nothing is replayed after app restart.
  DiaryFoodLogFeedbackControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryFoodLogFeedbackControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryFoodLogFeedbackControllerHash();

  @$internal
  @override
  DiaryFoodLogFeedbackController create() => DiaryFoodLogFeedbackController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<DiaryFoodLogFeedback> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<DiaryFoodLogFeedback>>(value),
    );
  }
}

String _$diaryFoodLogFeedbackControllerHash() =>
    r'ad0e7dc9d6e283804c7b6db2ad57b39a3fc49af0';

/// Transient presentation queue; nothing is replayed after app restart.

abstract class _$DiaryFoodLogFeedbackController
    extends $Notifier<List<DiaryFoodLogFeedback>> {
  List<DiaryFoodLogFeedback> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<List<DiaryFoodLogFeedback>, List<DiaryFoodLogFeedback>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                List<DiaryFoodLogFeedback>,
                List<DiaryFoodLogFeedback>
              >,
              List<DiaryFoodLogFeedback>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
