import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/features/home_widget/application/'
    'home_widget_click_action_provider.dart';
import 'package:yamt/features/home_widget/presentation/controllers/'
    'home_widget_sync_controller.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/scanner/presentation/shared/shared_receipt_listener.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Root application widget.
class YAMT extends ConsumerStatefulWidget {
  /// Creates app root.
  const new({super.key}); // coverage:ignore-line

  @override
  ConsumerState<YAMT> createState() => _YAMTState();
}

class _YAMTState extends ConsumerState<YAMT> {
  ProviderSubscription<AsyncValue<List<InventoryItem>>>?
  _inventoryWarmupSubscription;
  ProviderSubscription<AsyncValue<List<PreparedMeal>>>?
  _preparedMealsWarmupSubscription;
  ProviderSubscription<AsyncValue<ProductSearchHubInitialIntent>>?
  _homeWidgetClickSubscription;
  ProviderSubscription<void>? _homeWidgetSyncSubscription;

  @override
  void initState() {
    super.initState();
    _startInventoryWarmup();
    _startHomeWidgetSync();
  }

  @override
  void dispose() {
    _inventoryWarmupSubscription?.close();
    _preparedMealsWarmupSubscription?.close();
    _homeWidgetClickSubscription?.close();
    _homeWidgetSyncSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'YAMT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      builder: (context, child) => SharedReceiptListener(
        onReceiptSaved: () => ref.invalidate(inventoryItemsControllerProvider),
        child: child ?? const SizedBox.shrink(),
      ),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  void _startInventoryWarmup() {
    _inventoryWarmupSubscription ??= ref
        .listenManual<AsyncValue<List<InventoryItem>>>(
          inventoryItemsControllerProvider,
          _keepProviderWarm,
          fireImmediately: true,
        );
    _preparedMealsWarmupSubscription ??= ref
        .listenManual<AsyncValue<List<PreparedMeal>>>(
          preparedMealsControllerProvider,
          _keepProviderWarm,
          fireImmediately: true,
        );
  }

  void _keepProviderWarm<T>(T? previous, T next) {}

  void _startHomeWidgetSync() {
    // Auto-dispose sync controller: this listener keeps it and its
    // ref.listen subscriptions active for the app's lifetime, the same way
    // the warmups above do.
    _homeWidgetSyncSubscription ??= ref.listenManual<void>(
      homeWidgetSyncControllerProvider,
      _keepProviderWarm,
    );
    _homeWidgetClickSubscription ??= ref
        .listenManual<AsyncValue<ProductSearchHubInitialIntent>>(
          homeWidgetClickActionProvider,
          _openHomeWidgetQuickAction,
        );
  }

  void _openHomeWidgetQuickAction(
    AsyncValue<ProductSearchHubInitialIntent>? previous,
    AsyncValue<ProductSearchHubInitialIntent> next,
  ) {
    final intent = next.asData?.value;
    if (intent == null) {
      return;
    }
    final context = ref.read(navigatorKeyProvider).currentContext;
    if (context == null || !context.mounted) {
      return;
    }
    final now = ref.read(clockProvider)();
    unawaited(
      context.push<void>(
        AppRoutes.homeProductSearchHub,
        extra: ProductSearchHubRouteArgs.diary(
          initialIntent: intent,
          preselectedMealType: MealType.defaultForDateTime(now),
          preselectedLoggedAt: now,
        ),
      ),
    );
  }
}
