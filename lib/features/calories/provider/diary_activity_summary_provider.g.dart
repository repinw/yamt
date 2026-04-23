// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_activity_summary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Diary activity summary.

@ProviderFor(diaryActivitySummary)
final diaryActivitySummaryProvider = DiaryActivitySummaryProvider._();

/// Diary activity summary.

final class DiaryActivitySummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<DiaryActivitySummary>,
          DiaryActivitySummary,
          FutureOr<DiaryActivitySummary>
        >
    with
        $FutureModifier<DiaryActivitySummary>,
        $FutureProvider<DiaryActivitySummary> {
  /// Diary activity summary.
  DiaryActivitySummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryActivitySummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryActivitySummaryHash();

  @$internal
  @override
  $FutureProviderElement<DiaryActivitySummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DiaryActivitySummary> create(Ref ref) {
    return diaryActivitySummary(ref);
  }
}

String _$diaryActivitySummaryHash() =>
    r'ed2a340eabc70eda2dadc4812c0852e6c43e913d';
