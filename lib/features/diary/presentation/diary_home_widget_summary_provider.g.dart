// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_home_widget_summary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watches today's diary dashboard and exposes a flat summary for the
/// home-screen widget feature. Uses the same daily metrics as the Diary
/// balance card, so the widget shows the same numbers. `null` while today's
/// dashboard has not loaded yet.
///
/// Lives in `presentation/` because it derives from the dashboard
/// controller's state.

@ProviderFor(diaryHomeWidgetSummary)
final diaryHomeWidgetSummaryProvider = DiaryHomeWidgetSummaryProvider._();

/// Watches today's diary dashboard and exposes a flat summary for the
/// home-screen widget feature. Uses the same daily metrics as the Diary
/// balance card, so the widget shows the same numbers. `null` while today's
/// dashboard has not loaded yet.
///
/// Lives in `presentation/` because it derives from the dashboard
/// controller's state.

final class DiaryHomeWidgetSummaryProvider
    extends
        $FunctionalProvider<
          DiaryHomeWidgetSummary?,
          DiaryHomeWidgetSummary?,
          DiaryHomeWidgetSummary?
        >
    with $Provider<DiaryHomeWidgetSummary?> {
  /// Watches today's diary dashboard and exposes a flat summary for the
  /// home-screen widget feature. Uses the same daily metrics as the Diary
  /// balance card, so the widget shows the same numbers. `null` while today's
  /// dashboard has not loaded yet.
  ///
  /// Lives in `presentation/` because it derives from the dashboard
  /// controller's state.
  DiaryHomeWidgetSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryHomeWidgetSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryHomeWidgetSummaryHash();

  @$internal
  @override
  $ProviderElement<DiaryHomeWidgetSummary?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryHomeWidgetSummary? create(Ref ref) {
    return diaryHomeWidgetSummary(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryHomeWidgetSummary? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryHomeWidgetSummary?>(value),
    );
  }
}

String _$diaryHomeWidgetSummaryHash() =>
    r'742e65e6c58dc3ea1a9c73b34db59d93d9bfb964';
