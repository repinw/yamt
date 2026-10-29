// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_day_type_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Changes the day type of a diary day through the calorie goal controller.

@ProviderFor(DiaryDayTypeController)
final diaryDayTypeControllerProvider = DiaryDayTypeControllerProvider._();

/// Changes the day type of a diary day through the calorie goal controller.
final class DiaryDayTypeControllerProvider
    extends $AsyncNotifierProvider<DiaryDayTypeController, void> {
  /// Changes the day type of a diary day through the calorie goal controller.
  DiaryDayTypeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryDayTypeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryDayTypeControllerHash();

  @$internal
  @override
  DiaryDayTypeController create() => DiaryDayTypeController();
}

String _$diaryDayTypeControllerHash() =>
    r'd7d1c9f12b91abb0a12af876039f5cf1b4ba2424';

/// Changes the day type of a diary day through the calorie goal controller.

abstract class _$DiaryDayTypeController extends $AsyncNotifier<void> {
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
