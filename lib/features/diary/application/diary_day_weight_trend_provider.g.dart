// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_day_weight_trend_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The weights of the recent days that end on the diary [day], from manual
/// entries and the Health samples of all devices.
///
/// A future day shows the trend of today.

@ProviderFor(diaryDayWeightTrend)
final diaryDayWeightTrendProvider = DiaryDayWeightTrendFamily._();

/// The weights of the recent days that end on the diary [day], from manual
/// entries and the Health samples of all devices.
///
/// A future day shows the trend of today.

final class DiaryDayWeightTrendProvider
    extends
        $FunctionalProvider<
          AsyncValue<RecentWeightTrend>,
          RecentWeightTrend,
          FutureOr<RecentWeightTrend>
        >
    with
        $FutureModifier<RecentWeightTrend>,
        $FutureProvider<RecentWeightTrend> {
  /// The weights of the recent days that end on the diary [day], from manual
  /// entries and the Health samples of all devices.
  ///
  /// A future day shows the trend of today.
  DiaryDayWeightTrendProvider._({
    required DiaryDayWeightTrendFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryDayWeightTrendProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryDayWeightTrendHash();

  @override
  String toString() {
    return r'diaryDayWeightTrendProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RecentWeightTrend> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RecentWeightTrend> create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryDayWeightTrend(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryDayWeightTrendProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryDayWeightTrendHash() =>
    r'a3e158f61e14a7a00c3d1bce962ed75379fac157';

/// The weights of the recent days that end on the diary [day], from manual
/// entries and the Health samples of all devices.
///
/// A future day shows the trend of today.

final class DiaryDayWeightTrendFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RecentWeightTrend>, DateTime> {
  DiaryDayWeightTrendFamily._()
    : super(
        retry: null,
        name: r'diaryDayWeightTrendProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The weights of the recent days that end on the diary [day], from manual
  /// entries and the Health samples of all devices.
  ///
  /// A future day shows the trend of today.

  DiaryDayWeightTrendProvider call(DateTime day) =>
      DiaryDayWeightTrendProvider._(argument: day, from: this);

  @override
  String toString() => r'diaryDayWeightTrendProvider';
}
