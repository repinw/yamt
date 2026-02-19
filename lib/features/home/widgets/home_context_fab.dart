import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/home/home_tab_page.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/inventory/provider/fridge_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/presentation/widgets/inventory_receipt_actions_sheet.dart';
import 'package:yamt/features/scanner/presentation/widgets/inventory_receipt_review_sheet.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';

class HomeContextFab extends ConsumerWidget {
  const HomeContextFab({super.key, required this.currentTab});

  final HomeTabType currentTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(receiptCaptureFlowControllerProvider);
    final isFlowRunning = flowState.isLoading;
    final l10n = AppLocalizations.of(context)!;
    final fabChild = isFlowRunning
        ? const SizedBox.square(
            dimension: AppSizes.inlineProgressIndicator,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.progressStrokeWidth,
            ),
          )
        : const Icon(Icons.add);

    return FloatingActionButton.small(
      tooltip: _fabTooltip(l10n),
      onPressed: isFlowRunning ? null : () => _onPressed(context, ref, l10n),
      child: fabChild,
    );
  }

  String _fabTooltip(AppLocalizations l10n) {
    return switch (currentTab) {
      HomeTabType.inventory => l10n.inventoryFabTooltip,
      HomeTabType.shopping ||
      HomeTabType.calories ||
      HomeTabType.settings => l10n.homeQuickActionTooltip,
    };
  }

  Future<void> _onPressed(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    if (currentTab == HomeTabType.inventory) {
      await _openInventoryActionSheet(context, ref, l10n);
      return;
    }

    final message = _contextActionMessage(l10n);
    if (message == null) return;
    _showSnackBar(context, message);
  }

  String? _contextActionMessage(AppLocalizations l10n) {
    return switch (currentTab) {
      HomeTabType.shopping => l10n.homeShoppingActionContextPlaceholder,
      HomeTabType.calories => l10n.homeCaloriesActionContextPlaceholder,
      HomeTabType.settings => l10n.homeSettingsActionContextPlaceholder,
      HomeTabType.inventory => null,
    };
  }

  Future<void> _openInventoryActionSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final isCameraEnabled = ref.read(receiptCameraSupportedProvider);

    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return InventoryReceiptActionsSheet(
          isCameraEnabled: isCameraEnabled,
          onScanCameraTap: () {
            sheetContext.pop();
            unawaited(
              _runInventoryFlow(context, ref, l10n, ReceiptInputSource.camera),
            );
          },
          onUploadFileTap: () {
            sheetContext.pop();
            unawaited(
              _runInventoryFlow(context, ref, l10n, ReceiptInputSource.file),
            );
          },
        );
      },
    );
  }

  Future<void> _runInventoryFlow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ReceiptInputSource source,
  ) async {
    final controller = ref.read(receiptCaptureFlowControllerProvider.notifier);
    final result = await controller.run(source: source);
    if (!context.mounted) return;

    if (result.status == ReceiptCaptureFlowStatus.completed) {
      await _openReviewSheet(
        context: context,
        ref: ref,
        l10n: l10n,
        controller: controller,
        mappedItems: result.mappedItems ?? const <FridgeItem>[],
      );
      return;
    }

    final message = _messageForFlowResult(result, l10n);
    if (message == null) return;
    _showSnackBar(context, message);
  }

  Future<void> _openReviewSheet({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required ReceiptCaptureFlowController controller,
    required List<FridgeItem> mappedItems,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return InventoryReceiptReviewSheet(
          items: mappedItems,
          onCancelTap: () => sheetContext.pop(),
          onSaveTap: (reviewedItems) async {
            final saved = await controller.persistReviewedItems(reviewedItems);
            if (!sheetContext.mounted) {
              return;
            }
            sheetContext.pop();

            if (!context.mounted) {
              return;
            }

            if (saved) {
              ref.invalidate(fridgeItemsControllerProvider);
              _showSnackBar(context, l10n.inventoryReceiptSaveSucceeded);
              return;
            }
            _showSnackBar(context, l10n.inventoryReceiptSaveFailed);
          },
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

  void _showSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
