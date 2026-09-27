// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_weight_trend_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The weights of the last days from manual entries and Health samples.
///
/// Health samples load only when Health access is ready. Saving or deleting
/// a weight through `ManualHealthWeightEntriesController` refreshes it.

@ProviderFor(recentWeightTrend)
final recentWeightTrendProvider = RecentWeightTrendProvider._();

/// The weights of the last days from manual entries and Health samples.
///
/// Health samples load only when Health access is ready. Saving or deleting
/// a weight through `ManualHealthWeightEntriesController` refreshes it.

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
  /// The weights of the last days from manual entries and Health samples.
  ///
  /// Health samples load only when Health access is ready. Saving or deleting
  /// a weight through `ManualHealthWeightEntriesController` refreshes it.
  RecentWeightTrendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentWeightTrendProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentWeightTrendHash();

  @$internal
  @override
  $FutureProviderElement<RecentWeightTrend> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RecentWeightTrend> create(Ref ref) {
    return recentWeightTrend(ref);
  }
}

String _$recentWeightTrendHash() => r'3b131948f575d9e50e3f216351e6e45093539f7d';
