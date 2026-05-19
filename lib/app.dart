import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/seed_color_controller.dart';
import 'package:yamt/core/theme/theme_mode_controller.dart';
import 'package:yamt/core/widgets/app_background.dart';
import 'package:yamt/features/calories/application/'
    'calorie_health_connection_sync.dart';
import 'package:yamt/features/diary/application/diary_provider_warmup.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/scanner/presentation/shared_receipt_listener.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _calorieHealthSyncStartupDelay = Duration(seconds: 2);

/// Root application widget.
@Dependencies([
  appRouter,
  InventoryItemsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  diaryProviderWarmup,
])
class YAMT extends ConsumerStatefulWidget {
  /// Creates app root.
  const YAMT({super.key}); // coverage:ignore-line

  @override
  ConsumerState<YAMT> createState() => _YAMTState();
}

class _YAMTState extends ConsumerState<YAMT> {
  ProviderSubscription<void>? _calorieHealthSyncSubscription;
  Timer? _calorieHealthSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _calorieHealthSyncTimer ??= Timer(
        _calorieHealthSyncStartupDelay,
        _startCalorieHealthSync,
      );
    });
  }

  @override
  void dispose() {
    _calorieHealthSyncSubscription?.close();
    _calorieHealthSyncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(diaryProviderWarmupProvider);
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final seedColor = ref.watch(seedColorControllerProvider);

    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(seedColor: seedColor),
      darkTheme: AppTheme.dark(seedColor: seedColor),
      themeMode: themeMode,
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

  void _startCalorieHealthSync() {
    if (!mounted) {
      return;
    }
    _calorieHealthSyncSubscription ??= ref.listenManual<void>(
      calorieHealthConnectionSyncProvider,
      (_, _) {},
      fireImmediately: true,
    );
  }
}
