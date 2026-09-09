import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/presentation/controllers/guest_auth_controller.dart';

import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/presentation/shared_receipt_listener.dart';
import 'package:yamt/l10n/app_localizations.dart';


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
  ProviderSubscription<AsyncValue<List<InventoryItem>>>?
  _inventoryWarmupSubscription;
  ProviderSubscription<AsyncValue<List<PreparedMeal>>>?
  _preparedMealsWarmupSubscription;

  @override
  void initState() {
    super.initState();
    _ensureInitialGuestAuth();
    _startInventoryWarmup();
  }

  @override
  void dispose() {
    _initialAuthSubscription?.close();
    _inventoryWarmupSubscription?.close();
    _preparedMealsWarmupSubscription?.close();
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
        child: child ?? const SizedBox.shrink(),
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
