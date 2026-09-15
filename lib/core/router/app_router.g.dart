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
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
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

String _$navigatorKeyHash() => r'bd0bca3cd68c5a6268917ad1bacdc7beb17654bd';

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
    r'a1c61a2b76bcc24c6eb0ae2caafc335ede931515';

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
          navigatorKeyProvider,
          inventoryItemRepositoryProvider,
          inventoryManualAddQuickEatConfigProvider,
          diaryQuickEatInventoryProvider,
          diaryQuickEatInventoryActionsProvider,
          cookingFlowControllerProvider,
          cookingFlowWizardControllerProvider,
          cookingInstructionStepsProvider,
          inventoryItemsControllerProvider,
          preparedMealsControllerProvider,
          inventoryBackedCalorieEntrySaveFlowProvider,
          manualProductRecentItemsServiceProvider,
          preparedMealImagePickerProvider,
          receiptScanFlowCoordinatorProvider,
          receiptCameraSupportedProvider,
          inventoryActivityEventsProvider,
          inventoryShoppingSuggestionsProvider,
          receiptReviewControllerProvider,
          receiptManualProductPickerProvider,
          productSearchGatewayProvider,
          productSearchHubCompletionHandlerProvider,
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
          AppRouterProvider.$allTransitiveDependencies21,
          AppRouterProvider.$allTransitiveDependencies22,
          AppRouterProvider.$allTransitiveDependencies23,
          AppRouterProvider.$allTransitiveDependencies24,
          AppRouterProvider.$allTransitiveDependencies25,
          AppRouterProvider.$allTransitiveDependencies26,
          AppRouterProvider.$allTransitiveDependencies27,
          AppRouterProvider.$allTransitiveDependencies28,
          AppRouterProvider.$allTransitiveDependencies29,
        },
      );

  static final $allTransitiveDependencies0 = navigatorKeyProvider;
  static final $allTransitiveDependencies1 = inventoryItemRepositoryProvider;
  static final $allTransitiveDependencies2 =
      inventoryManualAddQuickEatConfigProvider;
  static final $allTransitiveDependencies3 = diaryQuickEatInventoryProvider;
  static final $allTransitiveDependencies4 =
      DiaryQuickEatInventoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies5 =
      DiaryQuickEatInventoryProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies6 =
      DiaryQuickEatInventoryProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies7 =
      DiaryQuickEatInventoryProvider.$allTransitiveDependencies4;
  static final $allTransitiveDependencies8 =
      DiaryQuickEatInventoryProvider.$allTransitiveDependencies5;
  static final $allTransitiveDependencies9 =
      DiaryQuickEatInventoryProvider.$allTransitiveDependencies6;
  static final $allTransitiveDependencies10 =
      diaryQuickEatInventoryActionsProvider;
  static final $allTransitiveDependencies11 = cookingFlowControllerProvider;
  static final $allTransitiveDependencies12 =
      cookingFlowWizardControllerProvider;
  static final $allTransitiveDependencies13 = cookingInstructionStepsProvider;
  static final $allTransitiveDependencies14 =
      inventoryBackedCalorieEntrySaveFlowProvider;
  static final $allTransitiveDependencies15 =
      manualProductRecentItemsServiceProvider;
  static final $allTransitiveDependencies16 = preparedMealImagePickerProvider;
  static final $allTransitiveDependencies17 =
      receiptScanFlowCoordinatorProvider;
  static final $allTransitiveDependencies18 =
      ReceiptScanFlowCoordinatorProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies19 =
      ReceiptScanFlowCoordinatorProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies20 =
      ReceiptScanFlowCoordinatorProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies21 = receiptCameraSupportedProvider;
  static final $allTransitiveDependencies22 = inventoryActivityEventsProvider;
  static final $allTransitiveDependencies23 =
      inventoryShoppingSuggestionsProvider;
  static final $allTransitiveDependencies24 =
      InventoryShoppingSuggestionsProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies25 = receiptReviewControllerProvider;
  static final $allTransitiveDependencies26 =
      ReceiptReviewControllerProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies27 =
      receiptManualProductPickerProvider;
  static final $allTransitiveDependencies28 = productSearchGatewayProvider;
  static final $allTransitiveDependencies29 =
      productSearchHubCompletionHandlerProvider;

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

String _$appRouterHash() => r'fd0ff40aeb1d58314b96a88ca60eab3c477e24b4';
