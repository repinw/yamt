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
          inventoryManualAddQuickEatConfigProvider,
          diaryProviderWarmupProvider,
          diaryQuickEatInventoryProvider,
          diaryQuickEatInventoryActionsProvider,
          inventoryBackedCalorieEntrySaveFlowProvider,
          cookingFlowControllerProvider,
          cookingFlowWizardControllerProvider,
          inventoryItemsControllerProvider,
          preparedMealsControllerProvider,
          manualProductRecentItemsServiceProvider,
          preparedMealImagePickerProvider,
          inventoryActivityEventsProvider,
          receiptCaptureFlowControllerProvider,
          receiptBatchFlowControllerProvider,
          receiptCameraSupportedProvider,
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
          AppRouterProvider.$allTransitiveDependencies8,
          AppRouterProvider.$allTransitiveDependencies9,
          AppRouterProvider.$allTransitiveDependencies10,
          AppRouterProvider.$allTransitiveDependencies11,
          AppRouterProvider.$allTransitiveDependencies12,
          AppRouterProvider.$allTransitiveDependencies13,
          AppRouterProvider.$allTransitiveDependencies14,
          AppRouterProvider.$allTransitiveDependencies15,
          AppRouterProvider.$allTransitiveDependencies16,
          AppRouterProvider.$allTransitiveDependencies17,
          AppRouterProvider.$allTransitiveDependencies18,
          AppRouterProvider.$allTransitiveDependencies19,
          AppRouterProvider.$allTransitiveDependencies20,
        },
      );

  static final $allTransitiveDependencies0 = inventoryItemRepositoryProvider;
  static final $allTransitiveDependencies1 =
      inventoryManualAddQuickEatConfigProvider;
  static final $allTransitiveDependencies2 = diaryProviderWarmupProvider;
  static final $allTransitiveDependencies3 =
      DiaryProviderWarmupProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies4 =
      DiaryProviderWarmupProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies5 =
      DiaryProviderWarmupProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies6 =
      DiaryProviderWarmupProvider.$allTransitiveDependencies4;
  static final $allTransitiveDependencies7 =
      DiaryProviderWarmupProvider.$allTransitiveDependencies5;
  static final $allTransitiveDependencies8 =
      DiaryProviderWarmupProvider.$allTransitiveDependencies6;
  static final $allTransitiveDependencies9 = diaryQuickEatInventoryProvider;
  static final $allTransitiveDependencies10 =
      diaryQuickEatInventoryActionsProvider;
  static final $allTransitiveDependencies11 =
      inventoryBackedCalorieEntrySaveFlowProvider;
  static final $allTransitiveDependencies12 = cookingFlowControllerProvider;
  static final $allTransitiveDependencies13 =
      cookingFlowWizardControllerProvider;
  static final $allTransitiveDependencies14 =
      manualProductRecentItemsServiceProvider;
  static final $allTransitiveDependencies15 = preparedMealImagePickerProvider;
  static final $allTransitiveDependencies16 = inventoryActivityEventsProvider;
  static final $allTransitiveDependencies17 =
      receiptCaptureFlowControllerProvider;
  static final $allTransitiveDependencies18 =
      ReceiptCaptureFlowControllerProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies19 =
      ReceiptCaptureFlowControllerProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies20 =
      receiptBatchFlowControllerProvider;

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

String _$appRouterHash() => r'0caed9134a5c95540ac831d6a47b49c031c5c778';
