// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides root navigator key for app routing.

@ProviderFor(navigatorKey)
final navigatorKeyProvider = NavigatorKeyProvider._();

/// Provides root navigator key for app routing.

final class NavigatorKeyProvider
    extends
        $FunctionalProvider<
          GlobalKey<NavigatorState>,
          GlobalKey<NavigatorState>,
          GlobalKey<NavigatorState>
        >
    with $Provider<GlobalKey<NavigatorState>> {
  /// Provides root navigator key for app routing.
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

/// Provides listenable used to refresh router redirects.

@ProviderFor(appRouterRefreshListenable)
final appRouterRefreshListenableProvider =
    AppRouterRefreshListenableProvider._();

/// Provides listenable used to refresh router redirects.

final class AppRouterRefreshListenableProvider
    extends
        $FunctionalProvider<
          Raw<AppRouterRefreshListenable>,
          Raw<AppRouterRefreshListenable>,
          Raw<AppRouterRefreshListenable>
        >
    with $Provider<Raw<AppRouterRefreshListenable>> {
  /// Provides listenable used to refresh router redirects.
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
    r'c90f6a4b9110c8907b9a098c180417172e99610c';

/// Provides application `GoRouter` instance.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Provides application `GoRouter` instance.

final class AppRouterProvider
    extends $FunctionalProvider<Raw<GoRouter>, Raw<GoRouter>, Raw<GoRouter>>
    with $Provider<Raw<GoRouter>> {
  /// Provides application `GoRouter` instance.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[
          inventoryItemRepositoryProvider,
          calorieEntryDeleteFlowProvider,
          inventoryBackedCalorieEntrySaveFlowProvider,
          inventoryItemsControllerProvider,
          preparedMealsControllerProvider,
          receiptCaptureFlowControllerProvider,
          receiptBatchFlowControllerProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          AppRouterProvider.$allTransitiveDependencies0,
          AppRouterProvider.$allTransitiveDependencies1,
          AppRouterProvider.$allTransitiveDependencies2,
          AppRouterProvider.$allTransitiveDependencies3,
          AppRouterProvider.$allTransitiveDependencies4,
          AppRouterProvider.$allTransitiveDependencies5,
          AppRouterProvider.$allTransitiveDependencies6,
          AppRouterProvider.$allTransitiveDependencies7,
        },
      );

  static final $allTransitiveDependencies0 = inventoryItemRepositoryProvider;
  static final $allTransitiveDependencies1 = calorieEntryDeleteFlowProvider;
  static final $allTransitiveDependencies2 =
      CalorieEntryDeleteFlowProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies3 =
      CalorieEntryDeleteFlowProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies4 =
      inventoryBackedCalorieEntrySaveFlowProvider;
  static final $allTransitiveDependencies5 =
      receiptCaptureFlowControllerProvider;
  static final $allTransitiveDependencies6 =
      ReceiptCaptureFlowControllerProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies7 = receiptBatchFlowControllerProvider;

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

String _$appRouterHash() => r'72ac75b0b0135429d2e3ac633ae9ad825a528e51';
