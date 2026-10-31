// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_dashboard_catalog.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The tiles the dashboard offers: the [diaryDashboardCatalog].

@ProviderFor(diaryDashboardTiles)
final diaryDashboardTilesProvider = DiaryDashboardTilesProvider._();

/// The tiles the dashboard offers: the [diaryDashboardCatalog].

final class DiaryDashboardTilesProvider
    extends
        $FunctionalProvider<
          List<DiaryDashboardTile>,
          List<DiaryDashboardTile>,
          List<DiaryDashboardTile>
        >
    with $Provider<List<DiaryDashboardTile>> {
  /// The tiles the dashboard offers: the [diaryDashboardCatalog].
  DiaryDashboardTilesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryDashboardTilesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryDashboardTilesHash();

  @$internal
  @override
  $ProviderElement<List<DiaryDashboardTile>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<DiaryDashboardTile> create(Ref ref) {
    return diaryDashboardTiles(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<DiaryDashboardTile> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<DiaryDashboardTile>>(value),
    );
  }
}

String _$diaryDashboardTilesHash() =>
    r'9c9c0be499da18905eacba144ecb4ca2193c983f';
