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
    r'e505684e491972dd79a45e0cebd28580304d90e0';
