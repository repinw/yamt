// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_action_usage_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the home action usage repository.

@ProviderFor(homeActionUsageRepository)
final homeActionUsageRepositoryProvider = HomeActionUsageRepositoryProvider._();

/// Provides the home action usage repository.

final class HomeActionUsageRepositoryProvider
    extends
        $FunctionalProvider<
          HomeActionUsageRepository,
          HomeActionUsageRepository,
          HomeActionUsageRepository
        >
    with $Provider<HomeActionUsageRepository> {
  /// Provides the home action usage repository.
  HomeActionUsageRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeActionUsageRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeActionUsageRepositoryHash();

  @$internal
  @override
  $ProviderElement<HomeActionUsageRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HomeActionUsageRepository create(Ref ref) {
    return homeActionUsageRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeActionUsageRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeActionUsageRepository>(value),
    );
  }
}

String _$homeActionUsageRepositoryHash() =>
    r'21867f9ad499a62071fd400cae7735a5f14ad752';
