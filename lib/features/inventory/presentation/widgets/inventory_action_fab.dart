import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/inventory_action_sheet_flow.dart';
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
])
class InventoryActionFab extends ConsumerStatefulWidget {
  /// The inventory action fab.
  const InventoryActionFab({super.key});

  @override
  ConsumerState<InventoryActionFab> createState() => _InventoryActionFabState();
}

class _InventoryActionFabState extends ConsumerState<InventoryActionFab> {
  final _fabKey = GlobalKey<ExpandableFabState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final flowState = ref.watch(receiptCaptureFlowControllerProvider);
    final batchState = ref.watch(receiptBatchFlowControllerProvider);
    final isCameraEnabled = ref.watch(receiptCameraSupportedProvider);
    final isBusy =
        flowState.isLoading ||
        batchState.status == ReceiptBatchFlowStatus.running;

    return ExpandableFab(
      key: _fabKey,
      type: ExpandableFabType.up,
      distance: 64,
      childrenAnimation: ExpandableFabAnimation.none,
      overlayStyle: ExpandableFabOverlayStyle(
        color: colors.scrim.withValues(alpha: 0.08),
      ),
      openButtonBuilder: FloatingActionButtonBuilder(
        size: AppInventoryEditorial.contextFabSize,
        builder: (context, onPressed, progress) {
          return _InventoryMainFabButton(
            isBusy: isBusy,
            icon: Icons.add_rounded,
            tooltip: l10n.inventoryFabTooltip,
            onPressed: isBusy ? null : onPressed,
          );
        },
      ),
      closeButtonBuilder: FloatingActionButtonBuilder(
        size: AppInventoryEditorial.contextFabSize,
        builder: (context, onPressed, progress) {
          return _InventoryMainFabButton(
            isBusy: false,
            icon: Icons.close_rounded,
            tooltip: l10n.inventoryFabTooltip,
            onPressed: onPressed,
          );
        },
      ),
      children: [
        _InventoryFabMenuAction(
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
        _InventoryFabMenuAction(
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
        _InventoryFabMenuAction(
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
        _InventoryFabMenuAction(
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
      ],
    );
  }

  void _runAction(Future<void> Function() action) {
    _fabKey.currentState?.close();
    unawaited(action());
  }
}

class _InventoryMainFabButton extends StatelessWidget {
  const _InventoryMainFabButton({
    required this.isBusy,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final bool isBusy;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foregroundColor = onPressed == null && !isBusy
        ? colors.onSurface.withValues(alpha: 0.38)
        : colors.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.primary),
      ),
      child: SizedBox.square(
        dimension: AppInventoryEditorial.contextFabSize,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: onPressed,
            child: Tooltip(
              message: tooltip,
              child: Center(
                child: _InventoryMainFabIcon(
                  isBusy: isBusy,
                  icon: icon,
                  foregroundColor: foregroundColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryMainFabIcon extends StatelessWidget {
  const _InventoryMainFabIcon({
    required this.isBusy,
    required this.icon,
    required this.foregroundColor,
  });

  final bool isBusy;
  final IconData icon;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    if (!isBusy) {
      return Icon(icon, color: foregroundColor, size: 36);
    }

    return SizedBox.square(
      dimension: AppSizes.inlineProgressIndicator,
      child: CircularProgressIndicator(
        color: foregroundColor,
        strokeWidth: AppSizes.progressStrokeWidth,
      ),
    );
  }
}

class _InventoryFabMenuAction extends StatelessWidget {
  const _InventoryFabMenuAction({
    required this.heroTag,
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
    String? tooltip,
  }) : tooltip = tooltip ?? label;

  final Object heroTag;
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final labelMaxWidth = (screenWidth - 128).clamp(120.0, 240.0);

    return Tooltip(
      message: tooltip,
      child: FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onPressed,
        icon: Icon(icon),
        label: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: labelMaxWidth),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
