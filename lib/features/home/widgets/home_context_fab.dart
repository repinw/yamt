import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/home/home_tab_page.dart';
import 'package:yamt/features/inventory/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/inventory/domain/receipt_input_models.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_receipt_actions_sheet.dart';
import 'package:yamt/features/inventory/provider/fridge_items_controller.dart';
import 'package:yamt/features/inventory/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/features/inventory/provider/receipt_input_capabilities.dart';
import 'package:yamt/l10n/app_localizations.dart';

class HomeContextFab extends ConsumerWidget {
  const HomeContextFab({super.key, required this.currentTab});

  final HomeTabType currentTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(receiptCaptureFlowControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return FloatingActionButton.small(
      tooltip: _fabTooltip(l10n),
      onPressed: () => _onPressed(context, ref, l10n),
      child: const Icon(Icons.add),
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
    switch (currentTab) {
      case HomeTabType.inventory:
        await _openInventoryActionSheet(context, ref, l10n);
        return;
      case HomeTabType.shopping:
        _showSnackBar(context, l10n.homeShoppingActionContextPlaceholder);
        return;
      case HomeTabType.calories:
        _showSnackBar(context, l10n.homeCaloriesActionContextPlaceholder);
        return;
      case HomeTabType.settings:
        _showSnackBar(context, l10n.homeSettingsActionContextPlaceholder);
        return;
    }
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
      ref.invalidate(fridgeItemsControllerProvider);
    }

    final message = _messageForFlowResult(result, l10n);
    if (message == null) return;
    _showSnackBar(context, message);
  }

  String? _messageForFlowResult(
    ReceiptCaptureFlowResult result,
    AppLocalizations l10n,
  ) {
    return switch (result.status) {
      ReceiptCaptureFlowStatus.completed =>
        l10n.inventoryReceiptAnalysisSucceeded,
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
