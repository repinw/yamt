// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_day_dashboard_live_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads live dashboard inputs through Diary's application boundary.

@ProviderFor(diaryDayDashboardLiveData)
final diaryDayDashboardLiveDataProvider = DiaryDayDashboardLiveDataFamily._();

/// Loads live dashboard inputs through Diary's application boundary.

final class DiaryDayDashboardLiveDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<DiaryDayDashboardLiveData>,
          DiaryDayDashboardLiveData,
          FutureOr<DiaryDayDashboardLiveData>
        >
    with
        $FutureModifier<DiaryDayDashboardLiveData>,
        $FutureProvider<DiaryDayDashboardLiveData> {
  /// Loads live dashboard inputs through Diary's application boundary.
  DiaryDayDashboardLiveDataProvider._({
    required DiaryDayDashboardLiveDataFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryDayDashboardLiveDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryDayDashboardLiveDataHash();

  @override
  String toString() {
    return r'diaryDayDashboardLiveDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DiaryDayDashboardLiveData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DiaryDayDashboardLiveData> create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryDayDashboardLiveData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryDayDashboardLiveDataProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryDayDashboardLiveDataHash() =>
    r'440ffa73b9d11392baed6ed34ee8cb303f9dc087';

/// Loads live dashboard inputs through Diary's application boundary.

final class DiaryDayDashboardLiveDataFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<DiaryDayDashboardLiveData>,
          DateTime
        > {
  DiaryDayDashboardLiveDataFamily._()
    : super(
        retry: null,
        name: r'diaryDayDashboardLiveDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads live dashboard inputs through Diary's application boundary.

  DiaryDayDashboardLiveDataProvider call(DateTime selectedDay) =>
      DiaryDayDashboardLiveDataProvider._(argument: selectedDay, from: this);

  @override
  String toString() => r'diaryDayDashboardLiveDataProvider';
}
