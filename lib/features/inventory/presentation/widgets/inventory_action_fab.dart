import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/inventory_action_sheet_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_fab_action_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_fab_menu_action.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_main_fab_button.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_flow_state.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory action fab.
@Dependencies([
  InventoryItemsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  receiptCameraSupported,
])
class InventoryActionFab extends ConsumerStatefulWidget {
  /// The inventory action fab for the shell Scaffold slot.
  const InventoryActionFab({super.key}) : embedded = false;

  /// The inventory action fab for inline empty-state placement.
  const InventoryActionFab.embedded({super.key}) : embedded = true;

  /// Whether to render inside normal content instead of Scaffold FAB chrome.
  final bool embedded;

  @override
  ConsumerState<InventoryActionFab> createState() => _InventoryActionFabState();
}

class _InventoryActionFabState extends ConsumerState<InventoryActionFab> {
  bool _isSheetOpen = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final flowState = ref.watch(receiptCaptureFlowControllerProvider);
    final batchState = ref.watch(receiptBatchFlowControllerProvider);
    final isCameraEnabled = ref.watch(receiptCameraSupportedProvider);
    final isBusy =
        flowState.isLoading ||
        batchState.status == ReceiptBatchFlowStatus.running;

    if (widget.embedded) {
      return InventoryMainFabButton(
        buttonKey: const Key('inventory_action_fab_button'),
        isBusy: isBusy,
        icon: Icons.add_rounded,
        tooltip: l10n.inventoryFabTooltip,
        onPressed: isBusy || _isSheetOpen
            ? null
            : () => _showActionsSheet(
                context: context,
                l10n: l10n,
                isCameraEnabled: isCameraEnabled,
              ),
      );
    }

    final actions = [
      InventoryFabMenuAction(
        key: const Key('inventory_action_manual_search_fab'),
        heroTag: 'inventory_action_manual_search_fab',
        icon: Icons.search_rounded,
        label: l10n.inventoryActionManualSearch,
        onPressed: isBusy
            ? null
            : () => _runAction(
                () => InventoryActionSheetFlow.openManualSearch(
                  context: context,
                  l10n: l10n,
                ),
              ),
      ),
      InventoryFabMenuAction(
        key: const Key('inventory_action_barcode_fab'),
        heroTag: 'inventory_action_barcode_fab',
        icon: Icons.qr_code_scanner_rounded,
        label: l10n.diaryQuickEatSourceBarcode,
        onPressed: isBusy
            ? null
            : () => _runAction(
                () => InventoryActionSheetFlow.openBarcodeScanner(
                  context: context,
                  l10n: l10n,
                ),
              ),
      ),
      InventoryFabMenuAction(
        key: const Key('inventory_action_ai_suggestion_fab'),
        heroTag: 'inventory_action_ai_suggestion_fab',
        icon: Icons.auto_awesome_rounded,
        label: l10n.inventoryActionAiSuggestion,
        onPressed: isBusy
            ? null
            : () => _runAction(
                () => InventoryActionSheetFlow.openAiSuggestion(
                  context: context,
                  l10n: l10n,
                ),
              ),
      ),
      InventoryFabMenuAction(
        key: const Key('inventory_action_upload_image_pdf_fab'),
        heroTag: 'inventory_action_upload_image_pdf_fab',
        icon: Icons.upload_file_rounded,
        label: l10n.inventoryActionUploadImagePdf,
        onPressed: isBusy
            ? null
            : () => _runAction(
                () => InventoryActionSheetFlow.uploadFile(
                  context: context,
                  ref: ref,
                  l10n: l10n,
                ),
              ),
      ),
      InventoryFabMenuAction(
        key: const Key('inventory_action_camera_fab'),
        heroTag: 'inventory_action_camera_fab',
        icon: Icons.photo_camera_rounded,
        label: l10n.inventoryActionCamera,
        tooltip: isCameraEnabled
            ? l10n.inventoryActionCamera
            : l10n.inventoryActionCameraUnsupported,
        onPressed: isBusy || !isCameraEnabled
            ? null
            : () => _runAction(
                () => InventoryActionSheetFlow.scanCamera(
                  context: context,
                  ref: ref,
                  l10n: l10n,
                ),
              ),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isExpanded)
          for (final action in actions) ...[
            action,
            const SizedBox(height: AppSpacing.sm),
          ],
        InventoryMainFabButton(
          buttonKey: const Key('inventory_action_fab_button'),
          isBusy: isBusy,
          icon: _isExpanded ? Icons.close_rounded : Icons.add_rounded,
          tooltip: l10n.inventoryFabTooltip,
          onPressed: isBusy ? null : _toggleExpanded,
        ),
      ],
    );
  }

  void _runAction(Future<void> Function() action) {
    setState(() {
      _isExpanded = false;
    });
    unawaited(action());
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _showActionsSheet({
    required BuildContext context,
    required AppLocalizations l10n,
    required bool isCameraEnabled,
  }) {
    if (_isSheetOpen) {
      return;
    }
    setState(() {
      _isSheetOpen = true;
    });
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        useSafeArea: true,
        sheetAnimationStyle: AnimationStyle.noAnimation,
        builder: (sheetContext) {
          return InventoryFabActionSheet(
            isCameraEnabled: isCameraEnabled,
            onManualSearch: () => _closeAndRun(
              sheetContext,
              () => InventoryActionSheetFlow.openManualSearch(
                context: context,
                l10n: l10n,
              ),
            ),
            onBarcodeScan: () => _closeAndRun(
              sheetContext,
              () => InventoryActionSheetFlow.openBarcodeScanner(
                context: context,
                l10n: l10n,
              ),
            ),
            onAiSuggestion: () => _closeAndRun(
              sheetContext,
              () => InventoryActionSheetFlow.openAiSuggestion(
                context: context,
                l10n: l10n,
              ),
            ),
            onUploadFile: () => _closeAndRun(
              sheetContext,
              () => InventoryActionSheetFlow.uploadFile(
                context: context,
                ref: ref,
                l10n: l10n,
              ),
            ),
            onScanCamera: () => _closeAndRun(
              sheetContext,
              () => InventoryActionSheetFlow.scanCamera(
                context: context,
                ref: ref,
                l10n: l10n,
              ),
            ),
          );
        },
      ).whenComplete(() {
        if (mounted) {
          setState(() {
            _isSheetOpen = false;
          });
        }
      }),
    );
  }

  void _closeAndRun(
    BuildContext sheetContext,
    Future<void> Function() action,
  ) {
    Navigator.of(sheetContext).pop();
    unawaited(action());
  }
}
