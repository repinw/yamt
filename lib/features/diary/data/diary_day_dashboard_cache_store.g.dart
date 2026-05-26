// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_day_dashboard_cache_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the diary dashboard cache store.

@ProviderFor(diaryDayDashboardCacheStore)
final diaryDayDashboardCacheStoreProvider =
    DiaryDayDashboardCacheStoreProvider._();

/// Provides the diary dashboard cache store.

final class DiaryDayDashboardCacheStoreProvider
    extends
        $FunctionalProvider<
          DiaryDayDashboardCacheStore,
          DiaryDayDashboardCacheStore,
          DiaryDayDashboardCacheStore
        >
    with $Provider<DiaryDayDashboardCacheStore> {
  /// Provides the diary dashboard cache store.
  DiaryDayDashboardCacheStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryDayDashboardCacheStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryDayDashboardCacheStoreHash();

  @$internal
  @override
  $ProviderElement<DiaryDayDashboardCacheStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryDayDashboardCacheStore create(Ref ref) {
    return diaryDayDashboardCacheStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryDayDashboardCacheStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryDayDashboardCacheStore>(value),
    );
  }
}

String _$diaryDayDashboardCacheStoreHash() =>
    r'b4f6e330a9335d02030afa5b8318418c1649441d';
