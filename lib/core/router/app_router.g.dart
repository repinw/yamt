// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(navigatorKey)
final navigatorKeyProvider = NavigatorKeyProvider._();

final class NavigatorKeyProvider
    extends
        $FunctionalProvider<
          GlobalKey<NavigatorState>,
          GlobalKey<NavigatorState>,
          GlobalKey<NavigatorState>
        >
    with $Provider<GlobalKey<NavigatorState>> {
  NavigatorKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigatorKeyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigatorKeyHash();

  @$internal
  @override
  $ProviderElement<GlobalKey<NavigatorState>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GlobalKey<NavigatorState> create(Ref ref) {
    return navigatorKey(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobalKey<NavigatorState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlobalKey<NavigatorState>>(value),
    );
  }
}

String _$navigatorKeyHash() => r'cca063af6cdf1e440f6eeb4ad84cf0449235735f';

@ProviderFor(appRouterRefreshListenable)
final appRouterRefreshListenableProvider =
    AppRouterRefreshListenableProvider._();

final class AppRouterRefreshListenableProvider
    extends
        $FunctionalProvider<
          Raw<AppRouterRefreshListenable>,
          Raw<AppRouterRefreshListenable>,
          Raw<AppRouterRefreshListenable>
        >
    with $Provider<Raw<AppRouterRefreshListenable>> {
  AppRouterRefreshListenableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterRefreshListenableProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterRefreshListenableHash();

  @$internal
  @override
  $ProviderElement<Raw<AppRouterRefreshListenable>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Raw<AppRouterRefreshListenable> create(Ref ref) {
    return appRouterRefreshListenable(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Raw<AppRouterRefreshListenable> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Raw<AppRouterRefreshListenable>>(
        value,
      ),
    );
  }
}

String _$appRouterRefreshListenableHash() =>
    r'490fc1cbea874d41749de65d39070ae29b5f24b1';

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

final class AppRouterProvider
    extends $FunctionalProvider<Raw<GoRouter>, Raw<GoRouter>, Raw<GoRouter>>
    with $Provider<Raw<GoRouter>> {
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<Raw<GoRouter>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Raw<GoRouter> create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Raw<GoRouter> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Raw<GoRouter>>(value),
    );
  }
}

String _$appRouterHash() => r'c80c1d571d129a1397236f3504b2ccecfb7fed75';
