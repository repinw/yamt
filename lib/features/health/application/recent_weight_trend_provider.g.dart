// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_weight_trend_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The weights of the last [dayCount] days from manual entries and the
/// Health samples of all devices.

@ProviderFor(recentWeightTrend)
final recentWeightTrendProvider = RecentWeightTrendFamily._();

/// The weights of the last [dayCount] days from manual entries and the
/// Health samples of all devices.

final class RecentWeightTrendProvider
    extends
        $FunctionalProvider<
          AsyncValue<RecentWeightTrend>,
          RecentWeightTrend,
          FutureOr<RecentWeightTrend>
        >
    with
        $FutureModifier<RecentWeightTrend>,
        $FutureProvider<RecentWeightTrend> {
  /// The weights of the last [dayCount] days from manual entries and the
  /// Health samples of all devices.
  RecentWeightTrendProvider._({
    required RecentWeightTrendFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'recentWeightTrendProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recentWeightTrendHash();

  @override
  String toString() {
    return r'recentWeightTrendProvider'
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
    final argument = this.argument as int;
    return recentWeightTrend(ref, dayCount: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecentWeightTrendProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recentWeightTrendHash() => r'7f1b275cd13ef9e44641853f04d992ca2e38b9ac';

/// The weights of the last [dayCount] days from manual entries and the
/// Health samples of all devices.

final class RecentWeightTrendFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RecentWeightTrend>, int> {
  RecentWeightTrendFamily._()
    : super(
        retry: null,
        name: r'recentWeightTrendProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The weights of the last [dayCount] days from manual entries and the
  /// Health samples of all devices.

  RecentWeightTrendProvider call({
    int dayCount = RecentWeightTrend.chartDayCount,
  }) => RecentWeightTrendProvider._(argument: dayCount, from: this);

  @override
  String toString() => r'recentWeightTrendProvider';
}
