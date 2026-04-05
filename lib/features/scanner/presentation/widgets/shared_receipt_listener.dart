import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/domain/shared_receipt_intent.dart';
import 'package:yamt/features/scanner/presentation/'
    'inventory_receipt_review_page.dart';
import 'package:yamt/features/scanner/presentation/receipt_batch_flow_runner.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/provider/shared_receipt_service.dart';
import 'package:yamt/l10n/app_localizations.dart';

class SharedReceiptListener extends ConsumerStatefulWidget {
  const SharedReceiptListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SharedReceiptListener> createState() {
    return _SharedReceiptListenerState();
  }
}

class _SharedReceiptListenerState extends ConsumerState<SharedReceiptListener> {
  ProviderSubscription<SharedReceiptIntent?>? _pendingSubscription;
  var _isHandlingShare = false;

  @override
  void initState() {
    super.initState();
    _pendingSubscription = ref.listenManual(
      pendingSharedReceiptIntentProvider,
      (previous, next) => _tryHandlePendingIntent(),
    );
  }

  @override
  void dispose() {
    _pendingSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sharedReceiptServiceProvider);
    ref.watch(appRouterProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _tryHandlePendingIntent();
      }
    });

    return widget.child;
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
    } on StateError {
      return false;
    }

    return path != AppRoutes.splash &&
        path != AppRoutes.welcome &&
        path != AppRoutes.guestNameSetup;
  }

  Future<void> _handlePendingIntent(SharedReceiptIntent pendingIntent) async {
    final navigatorContext = _navigatorContext;
    final l10n = navigatorContext == null
        ? null
        : AppLocalizations.of(navigatorContext);
    if (navigatorContext == null || l10n == null) {
      return;
    }

    final shouldScan = await _showConfirmationDialog(
      context: navigatorContext,
      l10n: l10n,
      pendingIntent: pendingIntent,
    );
    if (!mounted) {
      return;
    }

    if (shouldScan != true) {
      _consumePendingIntent(pendingIntent);
      return;
    }

    _consumePendingIntent(pendingIntent);

    if (pendingIntent.isBatch) {
      final batchNavigatorContext = _navigatorContext;
      if (batchNavigatorContext == null || !batchNavigatorContext.mounted) {
        return;
      }

      final runner = ReceiptBatchFlowRunner(
        context: batchNavigatorContext,
        ref: ref,
        l10n: l10n,
        onItemsSaved: () => ref.invalidate(inventoryItemsControllerProvider),
      );
      await runner.runSelections(pendingIntent.selections);
      return;
    }

    await _runSingleSelection(pendingIntent, l10n);
  }

  Future<void> _runSingleSelection(
    SharedReceiptIntent pendingIntent,
    AppLocalizations l10n,
  ) async {
    final controller = ref.read(receiptCaptureFlowControllerProvider.notifier);
    final navigatorContext = _navigatorContext;
    final navigatorState = ref.read(navigatorKeyProvider).currentState;
    if (navigatorContext == null || navigatorState == null) {
      return;
    }

    var loadingDialogOpen = true;
    final loadingDialog =
        showDialog<void>(
          context: navigatorContext,
          barrierDismissible: false,
          builder: (_) {
            return const Center(child: CircularProgressIndicator());
          },
        ).whenComplete(() {
          loadingDialogOpen = false;
        });

    final result = await controller.runSelection(
      selection: pendingIntent.selections.first,
    );

    if (loadingDialogOpen && navigatorState.mounted) {
      navigatorState.pop();
    }
    await loadingDialog;
    if (!mounted) {
      return;
    }

    if (result.status == ReceiptCaptureFlowStatus.completed) {
      await _openReviewPage(
        controller: controller,
        l10n: l10n,
        reviewDrafts: result.reviewDrafts ?? const <ReceiptReviewItemDraft>[],
        receiptPreviewBytes: result.receiptPreviewBytes,
      );
      return;
    }

    final message = _messageForFlowResult(result, l10n);
    if (message != null) {
      _showSnackBar(message);
    }
  }

  Future<bool> _openReviewPage({
    required ReceiptCaptureFlowController controller,
    required AppLocalizations l10n,
    required List<ReceiptReviewItemDraft> reviewDrafts,
    required Uint8List? receiptPreviewBytes,
  }) async {
    final navigatorContext = _navigatorContext;
    if (navigatorContext == null) {
      return false;
    }

    final saved = await navigatorContext.push<bool>(
      AppRoutes.homeInventoryReceiptReview,
      extra: InventoryReceiptReviewPageArgs(
        items: reviewDrafts,
        receiptPreviewBytes: receiptPreviewBytes,
        onSaveTap: (reviewedItems) async {
          final saved = await controller.persistReviewedItems(reviewedItems);
          if (!mounted) {
            return false;
          }

          if (saved) {
            ref.invalidate(inventoryItemsControllerProvider);
            _showSnackBar(l10n.inventoryReceiptSaveSucceeded);
            return true;
          }

          _showSnackBar(l10n.inventoryReceiptSaveFailed);
          return false;
        },
      ),
    );

    return saved ?? false;
  }

  void _consumePendingIntent(SharedReceiptIntent pendingIntent) {
    ref
        .read(pendingSharedReceiptIntentProvider.notifier)
        .consume(pendingIntent.requestId);
  }

  void _showSnackBar(String message) {
    final navigatorContext = _navigatorContext;
    if (navigatorContext == null) {
      return;
    }

    final messenger = ScaffoldMessenger.of(navigatorContext);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  BuildContext? get _navigatorContext {
    final navigatorContext = ref.read(navigatorKeyProvider).currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) {
      return null;
    }
    return navigatorContext;
  }
}

Future<bool?> _showConfirmationDialog({
  required BuildContext context,
  required AppLocalizations l10n,
  required SharedReceiptIntent pendingIntent,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.inventorySharedReceiptConfirmTitle),
        content: Text(
          pendingIntent.isBatch
              ? l10n.inventorySharedReceiptConfirmMultipleMessage(
                  pendingIntent.selections.length,
                )
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
      );
    },
  );
}

String? _messageForFlowResult(
  ReceiptCaptureFlowResult result,
  AppLocalizations l10n,
) {
  return switch (result.status) {
    ReceiptCaptureFlowStatus.completed => null,
    ReceiptCaptureFlowStatus.inputCanceled => null,
    ReceiptCaptureFlowStatus.inputUnsupported =>
      l10n.inventoryActionCameraUnsupported,
    ReceiptCaptureFlowStatus.inputFailed =>
      l10n.inventoryReceiptSelectionFailed,
    ReceiptCaptureFlowStatus.analysisFailed =>
      l10n.inventoryReceiptAnalysisFailed,
  };
}
