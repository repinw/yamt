import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/scanner/presentation/flow/receipt_scan_flow_coordinator.dart';
import 'package:yamt/features/scanner/presentation/shared/pending_shared_receipt_paths.dart';
import 'package:yamt/features/scanner/presentation/shared/shared_receipt_service.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _startupDelay = Duration(seconds: 1);

/// Widget wrapping the app to listen for incoming shared receipt files.
@Dependencies([
  navigatorKey,
  appRouter,
  SharedReceiptService,
  receiptScanFlowCoordinator,
])
class SharedReceiptListener extends ConsumerStatefulWidget {
  /// Creates a [SharedReceiptListener].
  const SharedReceiptListener({
    required this.child,
    this.onReceiptSaved,
    super.key,
  });

  /// The child widget (typically the app router/navigator).
  final Widget child;

  /// Optional callback executed when a shared receipt is successfully saved.
  final VoidCallback? onReceiptSaved;

  @override
  ConsumerState<SharedReceiptListener> createState() =>
      _SharedReceiptListenerState();
}

class _SharedReceiptListenerState extends ConsumerState<SharedReceiptListener> {
  ProviderSubscription<List<String>?>? _pendingSubscription;
  ProviderSubscription<AsyncValue<void>>? _serviceSubscription;
  Timer? _startupTimer;
  bool _isHandlingShare = false;

  @override
  void initState() {
    super.initState();
    _pendingSubscription = ref.listenManual(
      pendingSharedReceiptPathsProvider,
      (prev, next) => _tryHandlePendingPaths(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startupTimer ??= Timer(_startupDelay, _startService);
    });
  }

  @override
  void dispose() {
    _pendingSubscription?.close();
    _serviceSubscription?.close();
    _startupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appRouterProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tryHandlePendingPaths();
    });
    return widget.child;
  }

  void _startService() {
    if (!mounted) return;
    _serviceSubscription ??= ref.listenManual<AsyncValue<void>>(
      sharedReceiptServiceProvider,
      (_, _) {},
      fireImmediately: true,
    );
  }

  void _tryHandlePendingPaths() {
    if (_isHandlingShare || !_canProcessShare()) return;

    final paths = ref.read(pendingSharedReceiptPathsProvider);
    if (paths == null || paths.isEmpty) return;

    _isHandlingShare = true;
    unawaited(
      _handlePaths(paths).whenComplete(() {
        _isHandlingShare = false;
        if (mounted) _tryHandlePendingPaths();
      }),
    );
  }

  bool _canProcessShare() {
    final navContext = _navigatorContext;
    if (!mounted || navContext == null) return false;

    final router = ref.read(appRouterProvider);
    final path = router.routerDelegate.currentConfiguration.uri.path;

    return path != AppRoutes.splash &&
        path != AppRoutes.welcome &&
        path != AppRoutes.guestNameSetup &&
        path != AppRoutes.calorieGoalSetup;
  }

  Future<void> _handlePaths(List<String> paths) async {
    final navContext = _navigatorContext;
    if (navContext == null) return;

    final l10n = AppLocalizations.of(navContext);
    if (l10n == null) return;

    try {
      final confirmed = await _confirmScan(navContext, l10n, paths.length);
      if (!mounted) return;

      ref.read(pendingSharedReceiptPathsProvider.notifier).consume();
      if (!confirmed) return;

      final currentNavContext = _navigatorContext;
      if (currentNavContext == null || !currentNavContext.mounted) return;

      final coordinator = ref.read(receiptScanFlowCoordinatorProvider);
      final saved =
          await coordinator.processFilePaths(currentNavContext, paths);
      if (saved) {
        widget.onReceiptSaved?.call();
      }
    } on Exception {
      // Ignored: errors surfaced via coordinator SnackBar
    }
  }

  Future<bool> _confirmScan(
    BuildContext context,
    AppLocalizations l10n,
    int fileCount,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.inventorySharedReceiptConfirmTitle),
        content: Text(
          fileCount > 1
              ? l10n.inventorySharedReceiptConfirmMultipleMessage(fileCount)
              : l10n.inventorySharedReceiptConfirmSingleMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.inventoryReceiptReviewCancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.inventorySharedReceiptConfirmAction),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  BuildContext? get _navigatorContext {
    final nav = ref.read(navigatorKeyProvider).currentContext;
    if (nav == null || !nav.mounted) return null;
    return nav;
  }
}
