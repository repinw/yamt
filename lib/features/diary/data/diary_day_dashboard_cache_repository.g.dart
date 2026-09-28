// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_day_dashboard_cache_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the diary dashboard cache repository.

@ProviderFor(diaryDayDashboardCacheRepository)
final diaryDayDashboardCacheRepositoryProvider =
    DiaryDayDashboardCacheRepositoryProvider._();

/// Provides the diary dashboard cache repository.

final class DiaryDayDashboardCacheRepositoryProvider
    extends
        $FunctionalProvider<
          DiaryDayDashboardCacheRepository,
          DiaryDayDashboardCacheRepository,
          DiaryDayDashboardCacheRepository
        >
    with $Provider<DiaryDayDashboardCacheRepository> {
  /// Provides the diary dashboard cache repository.
  DiaryDayDashboardCacheRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryDayDashboardCacheRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryDayDashboardCacheRepositoryHash();

  @$internal
  @override
  $ProviderElement<DiaryDayDashboardCacheRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryDayDashboardCacheRepository create(Ref ref) {
    return diaryDayDashboardCacheRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryDayDashboardCacheRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryDayDashboardCacheRepository>(
        value,
      ),
    );
  }
}

String _$diaryDayDashboardCacheRepositoryHash() =>
    r'088f5ed047f0a7012624ffc9dd092485b963ca16';
