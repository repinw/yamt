import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/inventory_action_sheet_flow.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_flow_state.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryActionFab extends ConsumerWidget {
  const InventoryActionFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final flowState = ref.watch(receiptCaptureFlowControllerProvider);
    final batchState = ref.watch(receiptBatchFlowControllerProvider);
    final isBusy =
        flowState.isLoading ||
        batchState.status == ReceiptBatchFlowStatus.running;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppInventoryEditorialSurfaces.soulGradient(colors),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          AppInventoryEditorialSurfaces.ambientBoxShadow(
            colors,
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: SizedBox.square(
        dimension: AppInventoryEditorial.contextFabSize,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: isBusy ? null : () => _onPressed(context, ref, l10n),
            child: Tooltip(
              message: l10n.inventoryFabTooltip,
              child: Center(child: _InventoryActionFabChild(isBusy: isBusy)),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onPressed(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return InventoryActionSheetFlow.openActionSheet(
      context: context,
      ref: ref,
      l10n: l10n,
    );
  }
}

class _InventoryActionFabChild extends StatelessWidget {
  const _InventoryActionFabChild({required this.isBusy});

  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    if (!isBusy) {
      return const Icon(Icons.add, color: Colors.white, size: 36);
    }

    return const SizedBox.square(
      dimension: AppSizes.inlineProgressIndicator,
      child: CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: AppSizes.progressStrokeWidth,
      ),
    );
  }
}
