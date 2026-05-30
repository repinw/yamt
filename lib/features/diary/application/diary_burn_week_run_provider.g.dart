// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_burn_week_run_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Diary-facing Burn Week run state adapter.

@ProviderFor(diaryBurnWeekRunState)
final diaryBurnWeekRunStateProvider = DiaryBurnWeekRunStateProvider._();

/// Diary-facing Burn Week run state adapter.

final class DiaryBurnWeekRunStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<BurnWeekRunState>,
          BurnWeekRunState,
          FutureOr<BurnWeekRunState>
        >
    with $FutureModifier<BurnWeekRunState>, $FutureProvider<BurnWeekRunState> {
  /// Diary-facing Burn Week run state adapter.
  DiaryBurnWeekRunStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryBurnWeekRunStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryBurnWeekRunStateHash();

  @$internal
  @override
  $FutureProviderElement<BurnWeekRunState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BurnWeekRunState> create(Ref ref) {
    return diaryBurnWeekRunState(ref);
  }
}

String _$diaryBurnWeekRunStateHash() =>
    r'9eeeb8b89c43853778517594e30e9a98d840d2a7';

/// Actions needed by diary Burn Week presentation widgets.

@ProviderFor(diaryBurnWeekRunActions)
final diaryBurnWeekRunActionsProvider = DiaryBurnWeekRunActionsProvider._();

/// Actions needed by diary Burn Week presentation widgets.

final class DiaryBurnWeekRunActionsProvider
    extends
        $FunctionalProvider<
          DiaryBurnWeekRunActions,
          DiaryBurnWeekRunActions,
          DiaryBurnWeekRunActions
        >
    with $Provider<DiaryBurnWeekRunActions> {
  /// Actions needed by diary Burn Week presentation widgets.
  DiaryBurnWeekRunActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryBurnWeekRunActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryBurnWeekRunActionsHash();

  @$internal
  @override
  $ProviderElement<DiaryBurnWeekRunActions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryBurnWeekRunActions create(Ref ref) {
    return diaryBurnWeekRunActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryBurnWeekRunActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryBurnWeekRunActions>(value),
    );
  }
}

String _$diaryBurnWeekRunActionsHash() =>
    r'f86d3fe229aea0a93cd75c6bc8e01504b98492ed';
