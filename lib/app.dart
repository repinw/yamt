import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/seed_color_controller.dart';
import 'package:yamt/core/theme/theme_mode_controller.dart';
import 'package:yamt/core/widgets/app_background.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/presentation/controllers/guest_auth_controller.dart';
import 'package:yamt/features/calories/application/'
    'calorie_health_activity_cache_warmup.dart';
import 'package:yamt/features/calories/application/'
    'calorie_health_connection_sync.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/presentation/shared_receipt_listener.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _calorieHealthSyncStartupDelay = Duration(seconds: 2);

/// Root application widget.
@Dependencies([
  appRouter,
  InventoryItemsController,
  PreparedMealsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
])
class YAMT extends ConsumerStatefulWidget {
  /// Creates app root.
  const YAMT({super.key}); // coverage:ignore-line

  @override
  ConsumerState<YAMT> createState() => _YAMTState();
}

class _YAMTState extends ConsumerState<YAMT> {
  ProviderSubscription<AsyncValue<User?>>? _initialAuthSubscription;
  ProviderSubscription<void>? _calorieActivityCacheWarmupSubscription;
  ProviderSubscription<void>? _calorieHealthSyncSubscription;
  ProviderSubscription<AsyncValue<List<InventoryItem>>>?
  _inventoryWarmupSubscription;
  ProviderSubscription<AsyncValue<List<PreparedMeal>>>?
  _preparedMealsWarmupSubscription;
  Timer? _calorieHealthSyncTimer;

  @override
  void initState() {
    super.initState();
    _ensureInitialGuestAuth();
    _startInventoryWarmup();
    _calorieHealthSyncTimer = Timer(
      _calorieHealthSyncStartupDelay,
      _startCalorieHealthSync,
    );
  }

  @override
  void dispose() {
    _initialAuthSubscription?.close();
    _calorieActivityCacheWarmupSubscription?.close();
    _calorieHealthSyncSubscription?.close();
    _inventoryWarmupSubscription?.close();
    _preparedMealsWarmupSubscription?.close();
    _calorieHealthSyncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final seedColor = ref.watch(seedColorControllerProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'YAMT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(seedColor: seedColor),
      darkTheme: AppTheme.dark(seedColor: seedColor),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => SharedReceiptListener(
        child: AppBackground(child: child),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  void _ensureInitialGuestAuth() {
    _initialAuthSubscription ??= ref.listenManual<AsyncValue<User?>>(
      authStateChangesProvider,
      (previous, next) {
        final user = next.asData?.value;
        if (!next.isLoading && user == null) {
          unawaited(
            Future<void>(() async {
              try {
                await ref
                    .read(guestAuthControllerProvider.notifier)
                    .signInAnonymously();
              } on Object catch (e, st) {
                log(
                  'Initial guest auth skipped or failed: $e',
                  name: 'YAMT',
                  error: e,
                  stackTrace: st,
                );
              }
            }),
          );
        }
      },
      fireImmediately: true,
    );
  }

  void _startCalorieHealthSync() {
    if (!mounted) {
      return;
    }
    _calorieHealthSyncSubscription ??= ref.listenManual<void>(
      calorieHealthConnectionSyncProvider,
      (_, _) {},
      fireImmediately: true,
    );
    _calorieActivityCacheWarmupSubscription ??= ref.listenManual<void>(
      calorieHealthActivityCacheWarmupProvider,
      (_, _) {},
      fireImmediately: true,
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
}
