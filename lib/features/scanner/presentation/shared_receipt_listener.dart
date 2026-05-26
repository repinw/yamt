import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/scanner/application/shared_receipt_service.dart';
import 'package:yamt/features/scanner/domain/shared_receipt_intent.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/presentation/'
    'shared_receipt_flow_runner.dart';
import 'package:yamt/features/scanner/provider/'
    'pending_shared_receipt_intent.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _sharedReceiptServiceStartupDelay = Duration(seconds: 1);

/// Defines shared receipt listener.
@Dependencies([
  appRouter,
  InventoryItemsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
])
class SharedReceiptListener extends ConsumerStatefulWidget {
  /// The shared receipt listener.
  const SharedReceiptListener({required this.child, super.key});

  /// The child.
  final Widget child;

  @override
  ConsumerState<SharedReceiptListener> createState() {
    return _SharedReceiptListenerState();
  }
}

class _SharedReceiptListenerState extends ConsumerState<SharedReceiptListener> {
  ProviderSubscription<SharedReceiptIntent?>? _pendingSubscription;
  ProviderSubscription<AsyncValue<void>>? _serviceSubscription;
  Timer? _serviceStartupTimer;
  var _isHandlingShare = false;

  @override
  void initState() {
    super.initState();
    _pendingSubscription = ref.listenManual(
      pendingSharedReceiptIntentProvider,
      (previous, next) => _tryHandlePendingIntent(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _serviceStartupTimer ??= Timer(
        _sharedReceiptServiceStartupDelay,
        _startSharedReceiptService,
      );
    });
  }

  @override
  void dispose() {
    _pendingSubscription?.close();
    _serviceSubscription?.close();
    _serviceStartupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appRouterProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _tryHandlePendingIntent();
      }
    });

    return widget.child;
  }

  void _startSharedReceiptService() {
    if (!mounted) {
      return;
    }
    _serviceSubscription ??= ref.listenManual<AsyncValue<void>>(
      sharedReceiptServiceProvider,
      (_, _) {},
      fireImmediately: true,
    );
  }

  void _tryHandlePendingIntent() {
    if (_isHandlingShare || !_canProcessPendingShare()) {
      return;
    }

    final pendingIntent = ref.read(pendingSharedReceiptIntentProvider);
    if (pendingIntent == null) {
      return;
    }

    _isHandlingShare = true;
    unawaited(
      _handlePendingIntent(pendingIntent).whenComplete(() {
        _isHandlingShare = false;
        if (mounted) {
          _tryHandlePendingIntent();
        }
      }),
    );
  }

  bool _canProcessPendingShare() {
    final navigatorContext = _navigatorContext;
    if (!mounted || navigatorContext == null) {
      return false;
    }

    String path;
    try {
      path = ref.read(appRouterProvider).state.uri.path;
      // Router state may be unavailable while the listener starts.
      // ignore: avoid_catching_errors
    } on StateError {
      return false;
    }

    return path != AppRoutes.splash &&
        path != AppRoutes.welcome &&
        path != AppRoutes.guestNameSetup &&
        path != AppRoutes.calorieGoalSetup;
  }

  Future<void> _handlePendingIntent(SharedReceiptIntent pendingIntent) async {
    final flowRunner = _sharedReceiptFlowRunner;
    if (flowRunner == null) {
      return;
    }

    try {
      final shouldScan = await flowRunner.confirmScan(pendingIntent);
      if (!mounted) {
        return;
      }

      _consumePendingIntent(pendingIntent);
      if (!shouldScan) {
        return;
      }

      await flowRunner.runConfirmed(pendingIntent);
    } finally {
      flowRunner.dispose();
    }
  }

  void _consumePendingIntent(SharedReceiptIntent pendingIntent) {
    ref
        .read(pendingSharedReceiptIntentProvider.notifier)
        .consume(pendingIntent.requestId);
  }

  SharedReceiptFlowRunner? get _sharedReceiptFlowRunner {
    final navigatorContext = _navigatorContext;
    if (navigatorContext == null) {
      return null;
    }

    final l10n = AppLocalizations.of(navigatorContext);
    if (l10n == null) {
      return null;
    }

    return SharedReceiptFlowRunner(
      context: navigatorContext,
      ref: ref,
      l10n: l10n,
    );
  }

  BuildContext? get _navigatorContext {
    final navigatorContext = ref.read(navigatorKeyProvider).currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) {
      return null;
    }
    return navigatorContext;
  }
}
