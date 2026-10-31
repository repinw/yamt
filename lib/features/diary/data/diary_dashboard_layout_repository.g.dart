// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_dashboard_layout_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the dashboard layout repository of the signed-in user.

@ProviderFor(diaryDashboardLayoutRepository)
final diaryDashboardLayoutRepositoryProvider =
    DiaryDashboardLayoutRepositoryProvider._();

/// Provides the dashboard layout repository of the signed-in user.

final class DiaryDashboardLayoutRepositoryProvider
    extends
        $FunctionalProvider<
          DiaryDashboardLayoutRepository,
          DiaryDashboardLayoutRepository,
          DiaryDashboardLayoutRepository
        >
    with $Provider<DiaryDashboardLayoutRepository> {
  /// Provides the dashboard layout repository of the signed-in user.
  DiaryDashboardLayoutRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryDashboardLayoutRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryDashboardLayoutRepositoryHash();

  @$internal
  @override
  $ProviderElement<DiaryDashboardLayoutRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryDashboardLayoutRepository create(Ref ref) {
    return diaryDashboardLayoutRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryDashboardLayoutRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryDashboardLayoutRepository>(
        value,
      ),
    );
  }
}

String _$diaryDashboardLayoutRepositoryHash() =>
    r'2125a69ac79dbf495f97a5dbc0f30b639646c7c5';
