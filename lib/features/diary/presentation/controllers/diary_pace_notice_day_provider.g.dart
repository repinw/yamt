// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_pace_notice_day_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What today's pace notices need; no value while they are off, the pace
/// marker is off, nobody is signed in, or today is a pause day; loading
/// while the data key or today's balance loads; an error when the data key
/// failed to load.

@ProviderFor(diaryPaceNoticeDay)
final diaryPaceNoticeDayProvider = DiaryPaceNoticeDayProvider._();

/// What today's pace notices need; no value while they are off, the pace
/// marker is off, nobody is signed in, or today is a pause day; loading
/// while the data key or today's balance loads; an error when the data key
/// failed to load.

final class DiaryPaceNoticeDayProvider
    extends
        $FunctionalProvider<
          AsyncValue<DiaryPaceDay?>,
          AsyncValue<DiaryPaceDay?>,
          AsyncValue<DiaryPaceDay?>
        >
    with $Provider<AsyncValue<DiaryPaceDay?>> {
  /// What today's pace notices need; no value while they are off, the pace
  /// marker is off, nobody is signed in, or today is a pause day; loading
  /// while the data key or today's balance loads; an error when the data key
  /// failed to load.
  DiaryPaceNoticeDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryPaceNoticeDayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryPaceNoticeDayHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<DiaryPaceDay?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<DiaryPaceDay?> create(Ref ref) {
    return diaryPaceNoticeDay(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<DiaryPaceDay?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<DiaryPaceDay?>>(value),
    );
  }
}

String _$diaryPaceNoticeDayHash() =>
    r'ba03642e9fe80f47ab14dbed2465edfbc814db23';

/// Tomorrow's notice data, with the budget from the same week overview the
/// budget card shows when the user opens tomorrow: carryover (#911), training
/// days, and pause day. Loading while the data key or the budget loads, an
/// error when either failed to load; no budget when nobody is signed in.

@ProviderFor(diaryPaceTomorrowTarget)
final diaryPaceTomorrowTargetProvider = DiaryPaceTomorrowTargetProvider._();

/// Tomorrow's notice data, with the budget from the same week overview the
/// budget card shows when the user opens tomorrow: carryover (#911), training
/// days, and pause day. Loading while the data key or the budget loads, an
/// error when either failed to load; no budget when nobody is signed in.

final class DiaryPaceTomorrowTargetProvider
    extends
        $FunctionalProvider<
          AsyncValue<DiaryPaceTomorrow>,
          AsyncValue<DiaryPaceTomorrow>,
          AsyncValue<DiaryPaceTomorrow>
        >
    with $Provider<AsyncValue<DiaryPaceTomorrow>> {
  /// Tomorrow's notice data, with the budget from the same week overview the
  /// budget card shows when the user opens tomorrow: carryover (#911), training
  /// days, and pause day. Loading while the data key or the budget loads, an
  /// error when either failed to load; no budget when nobody is signed in.
  DiaryPaceTomorrowTargetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryPaceTomorrowTargetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryPaceTomorrowTargetHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<DiaryPaceTomorrow>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<DiaryPaceTomorrow> create(Ref ref) {
    return diaryPaceTomorrowTarget(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<DiaryPaceTomorrow> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<DiaryPaceTomorrow>>(
        value,
      ),
    );
  }
}

String _$diaryPaceTomorrowTargetHash() =>
    r'2d9e87eb6398bdfc1ead5f44bafe290fd8fc3657';
