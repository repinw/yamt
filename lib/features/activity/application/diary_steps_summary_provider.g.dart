// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_steps_summary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides real step data for one diary day.

@ProviderFor(diaryStepsSummary)
final diaryStepsSummaryProvider = DiaryStepsSummaryFamily._();

/// Provides real step data for one diary day.

final class DiaryStepsSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<DiaryActivitySummary>,
          DiaryActivitySummary,
          FutureOr<DiaryActivitySummary>
        >
    with
        $FutureModifier<DiaryActivitySummary>,
        $FutureProvider<DiaryActivitySummary> {
  /// Provides real step data for one diary day.
  DiaryStepsSummaryProvider._({
    required DiaryStepsSummaryFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryStepsSummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryStepsSummaryHash();

  @override
  String toString() {
    return r'diaryStepsSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DiaryActivitySummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DiaryActivitySummary> create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryStepsSummary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryStepsSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryStepsSummaryHash() => r'3f414a15dd540dca41a156ba0f1b4063857c1337';

/// Provides real step data for one diary day.

final class DiaryStepsSummaryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DiaryActivitySummary>, DateTime> {
  DiaryStepsSummaryFamily._()
    : super(
        retry: null,
        name: r'diaryStepsSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides real step data for one diary day.

  DiaryStepsSummaryProvider call(DateTime day) =>
      DiaryStepsSummaryProvider._(argument: day, from: this);

  @override
  String toString() => r'diaryStepsSummaryProvider';
}
