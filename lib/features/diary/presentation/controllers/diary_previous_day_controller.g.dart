// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_previous_day_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Closes or reopens the day before a planned day, so the planned day counts
/// like a started day with its carryover.

@ProviderFor(DiaryPreviousDayController)
final diaryPreviousDayControllerProvider =
    DiaryPreviousDayControllerProvider._();

/// Closes or reopens the day before a planned day, so the planned day counts
/// like a started day with its carryover.
final class DiaryPreviousDayControllerProvider
    extends $AsyncNotifierProvider<DiaryPreviousDayController, void> {
  /// Closes or reopens the day before a planned day, so the planned day counts
  /// like a started day with its carryover.
  DiaryPreviousDayControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryPreviousDayControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryPreviousDayControllerHash();

  @$internal
  @override
  DiaryPreviousDayController create() => DiaryPreviousDayController();
}

String _$diaryPreviousDayControllerHash() =>
    r'0c74988ed33d9801098bdef7ae931c643bf4a100';

/// Closes or reopens the day before a planned day, so the planned day counts
/// like a started day with its carryover.

abstract class _$DiaryPreviousDayController extends $AsyncNotifier<void> {
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
