import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/guest_name_setup_page.dart';
import 'package:yamt/features/auth/provider/'
    'auth_profile_setup_status_provider.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/auth/welcome_page.dart';
import 'package:yamt/features/calories/application/'
    'calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/calories/presentation/'
    'burn_week_mock_page.dart';
import 'package:yamt/features/calories/presentation/calorie_entry_editor_page.dart';
import 'package:yamt/features/calories/presentation/'
    'calorie_goal_onboarding_page.dart';
import 'package:yamt/features/calories/presentation/'
    'calorie_health_trends_page.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_onboarding_completed_provider.dart';
import 'package:yamt/features/diary/presentation/diary_page.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/household/presentation/household_page.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/presentation/inventory_manual_add_page.dart';
import 'package:yamt/features/inventory/presentation/inventory_page.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/features/meal_templates/presentation/'
    'meal_template_detail_page.dart';
import 'package:yamt/features/meal_templates/presentation/'
    'meal_template_import_review_page.dart';
import 'package:yamt/features/meal_templates/presentation/meal_templates_page.dart';
import 'package:yamt/features/meal_templates/presentation/models/'
    'meal_template_import_review_args.dart';
import 'package:yamt/features/scanner/presentation/'
    'inventory_receipt_review_page.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';
import 'package:yamt/features/settings/account_page.dart';
import 'package:yamt/features/settings/settings_page.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_page.dart';
import 'package:yamt/features/statistics/presentation/statistics_page.dart';

part 'app_router.g.dart';

/// Provides root navigator key for app routing.
@Riverpod(keepAlive: true)
GlobalKey<NavigatorState> navigatorKey(Ref ref) {
  return GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');
}

/// Provides listenable used to refresh router redirects.
@Riverpod(keepAlive: true)
Raw<AppRouterRefreshListenable> appRouterRefreshListenable(Ref ref) {
  final listenable = AppRouterRefreshListenable();
  ref
    ..onDispose(listenable.dispose)
    ..listen(authStateChangesProvider, (previous, next) {
      listenable.refresh();
    })
    ..listen(authProfileSetupCompletedProvider, (previous, next) {
      listenable.refresh();
    })
    ..listen(calorieGoalOnboardingCompletedProvider, (previous, next) {
      listenable.refresh();
    });
  return listenable;
}

/// Provides application `GoRouter` instance.
@Riverpod(
  keepAlive: true,
  dependencies: [
    inventoryItemRepository,
    calorieEntryDeleteFlow,
    inventoryBackedCalorieEntrySaveFlow,
    InventoryItemsController,
    PreparedMealsController,
    preparedMealImagePicker,
    ReceiptCaptureFlowController,
    ReceiptBatchFlowController,
    receiptCameraSupported,
  ],
)
Raw<GoRouter> appRouter(Ref ref) {
  final navigatorKey = ref.watch(navigatorKeyProvider);
  final refreshListenable = ref.watch(appRouterRefreshListenableProvider);
  final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.root,
    refreshListenable: refreshListenable,
    redirect: (context, state) => _redirectForState(ref, state),
    routes: [
      GoRoute(
        path: AppRoutes.root,
        redirect: (context, state) {
          final authState = ref.read(authStateChangesProvider);
          final isAuthenticated = authState.asData?.value != null;
          return isAuthenticated ? AppRoutes.homeDiary : AppRoutes.welcome;
        },
      ),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _AuthLoadingPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.guestNameSetup,
        builder: (context, state) => const GuestNameSetupPage(),
      ),
      GoRoute(
        path: AppRoutes.calorieGoalSetup,
        builder: (context, state) => const CalorieGoalOnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        redirect: (context, state) => AppRoutes.homeDiary,
      ),
      GoRoute(
        path: AppRoutes.homeSettingsAccount,
        builder: (context, state) => const AccountPage(),
      ),
      GoRoute(
        path: AppRoutes.homeSettingsHousehold,
        builder: (context, state) => const HouseholdPage(),
      ),
      if (kDebugMode)
        // Burn Week mock route is debug-only. Keep mock pages out of
        // user-facing builds.
        GoRoute(
          path: AppRoutes.homeCaloriesBurnWeekMock,
          builder: (context, state) => const BurnWeekMockPage(),
        ),
      GoRoute(
        path: AppRoutes.homeStatisticsWeight,
        builder: (context, state) => const CalorieHealthTrendsPage(),
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryCreate,
        redirect: (context, state) {
          final args = state.extra;
          if (args is! CalorieEntryCreateArgs ||
              args.inventoryContext == null) {
            return AppRoutes.homeInventory;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as CalorieEntryCreateArgs;
          return CalorieEntryEditorPage(
            prefilledProfile: args.prefilledProfile,
            scannedSourceRef: args.scannedSourceRef,
            inventoryContext: args.inventoryContext,
            preselectedMealType: args.preselectedMealType,
            preselectedLoggedAt: args.preselectedLoggedAt,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryDetails,
        pageBuilder: (context, state) {
          final entryId = state.pathParameters['entryId'];
          return _ModalBottomSheetPage<void>(
            key: state.pageKey,
            child: CalorieEntryEditorPage(entryId: entryId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.homeInventoryManualAdd,
        builder: (context, state) {
          final args = resolveInventoryManualAddRouteArgs(state.extra);
          return InventoryManualAddPage(
            initialAction: args.initialAction,
            quickEatOnly: args.quickEatOnly,
            preselectedMealType: args.preselectedMealType,
            preselectedLoggedAt: args.preselectedLoggedAt,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.homeInventoryReceiptReview,
        builder: (context, state) {
          final args = state.extra;
          if (args is! InventoryReceiptReviewPageArgs) {
            throw ArgumentError(
              'Inventory receipt review route requires '
              'InventoryReceiptReviewPageArgs.',
            );
          }
          return InventoryReceiptReviewPage(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.homeInventoryTemplateImportReview,
        builder: (context, state) {
          final args = state.extra;
          if (args is! MealTemplateImportReviewArgs) {
            throw ArgumentError(
              'Meal template import review route requires '
              'MealTemplateImportReviewArgs.',
            );
          }
          return MealTemplateImportReviewPage(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.homeInventoryTemplateDetail,
        builder: (context, state) {
          final templateId = state.pathParameters['templateId'] ?? '';
          return MealTemplateDetailPage(templateId: templateId);
        },
      ),
      GoRoute(
        path: AppRoutes.homeShopping,
        builder: (context, state) => const ShoppingListPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomePage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeInventory,
                builder: (context, state) {
                  final expandedPreparedMealId = state.extra is String
                      ? state.extra! as String
                      : null;
                  return InventoryPage(
                    expandedPreparedMealId: expandedPreparedMealId,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeDiary,
                builder: (context, state) => const DiaryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeInventoryTemplates,
                builder: (context, state) {
                  return const MealTemplatesPage(includeAppBar: false);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeStatistics,
                builder: (context, state) => const StatisticsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeSettings,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}

/// Resolves manual-add route extras while preserving legacy enum extras.
@visibleForTesting
InventoryManualAddRouteArgs resolveInventoryManualAddRouteArgs(Object? extra) {
  if (extra is InventoryManualAddRouteArgs) {
    return extra;
  }
  return InventoryManualAddRouteArgs(
    initialAction: extra is InventoryManualAddInitialAction
        ? extra
        : InventoryManualAddInitialAction.launcher,
  );
}

String? _redirectForState(Ref ref, GoRouterState state) {
  final authState = ref.read(authStateChangesProvider);
  final isAuthLoading = authState.isLoading;
  final currentUser = authState.asData?.value;
  final isAuthenticated = currentUser != null;
  final hasCompletedProfileSetup = ref.read(authProfileSetupCompletedProvider);
  final needsGuestNameSetup = isAuthenticated && !hasCompletedProfileSetup;
  final calorieGoalOnboardingState = isAuthenticated && hasCompletedProfileSetup
      ? ref.read(calorieGoalOnboardingCompletedProvider)
      : const AsyncData<bool>(false);
  final isCalorieGoalOnboardingLoading =
      isAuthenticated &&
      hasCompletedProfileSetup &&
      calorieGoalOnboardingState.isLoading;
  final hasCompletedCalorieGoalOnboarding =
      calorieGoalOnboardingState.asData?.value ?? false;
  final needsCalorieGoalSetup =
      isAuthenticated &&
      hasCompletedProfileSetup &&
      !isCalorieGoalOnboardingLoading &&
      !hasCompletedCalorieGoalOnboarding;
  final path = state.matchedLocation;
  final isStartupRoute = path == AppRoutes.root || path == AppRoutes.splash;

  if (isAuthLoading) {
    return path == AppRoutes.splash ? null : AppRoutes.splash;
  }

  if (!isAuthenticated) {
    return path == AppRoutes.welcome ? null : AppRoutes.welcome;
  }

  if (needsGuestNameSetup) {
    return path == AppRoutes.guestNameSetup ? null : AppRoutes.guestNameSetup;
  }

  if (isCalorieGoalOnboardingLoading) {
    final shouldBlockOnboardingRoute =
        isStartupRoute || path == AppRoutes.calorieGoalSetup;
    return shouldBlockOnboardingRoute ? AppRoutes.splash : null;
  }

  if (needsCalorieGoalSetup) {
    return path == AppRoutes.calorieGoalSetup
        ? null
        : AppRoutes.calorieGoalSetup;
  }

  if (path == AppRoutes.guestNameSetup) {
    return AppRoutes.homeDiary;
  }

  if (path == AppRoutes.calorieGoalSetup) {
    return AppRoutes.homeDiary;
  }

  if (path == AppRoutes.welcome || isStartupRoute) {
    return AppRoutes.homeDiary;
  }

  return null;
}

/// Change notifier bridge used to refresh `GoRouter`.
class AppRouterRefreshListenable extends ChangeNotifier {
  /// Triggers one router refresh cycle.
  void refresh() {
    notifyListeners();
  }
}

class _ModalBottomSheetPage<T> extends Page<T> {
  const _ModalBottomSheetPage({required this.child, super.key});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      settings: this,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => child,
    );
  }
}

class _AuthLoadingPage extends StatelessWidget {
  const _AuthLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
