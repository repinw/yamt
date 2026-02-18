import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/inventory/domain/receipt_input_models.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_receipt_actions_sheet.dart';
import 'package:yamt/features/inventory/provider/receipt_input_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class HomeContextFab extends ConsumerWidget {
  const HomeContextFab({super.key, required this.currentTabIndex});

  final int currentTabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return FloatingActionButton.small(
      tooltip: _fabTooltip(l10n),
      onPressed: () => _onPressed(context, ref, l10n),
      child: const Icon(Icons.add),
    );
  }

  String _fabTooltip(AppLocalizations l10n) {
    if (currentTabIndex == 0) {
      return l10n.inventoryFabTooltip;
    }

    return l10n.homeQuickActionTooltip;
  }

  Future<void> _onPressed(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    switch (currentTabIndex) {
      case 0:
        await _openInventoryActionSheet(context, ref, l10n);
        return;
      case 1:
        _showSnackBar(context, l10n.homeShoppingActionContextPlaceholder);
        return;
      case 2:
        _showSnackBar(context, l10n.homeCaloriesActionContextPlaceholder);
        return;
      case 3:
        _showSnackBar(context, l10n.homeSettingsActionContextPlaceholder);
        return;
      default:
        _showSnackBar(context, l10n.homeQuickActionTapped);
        return;
    }
  }

  Future<void> _openInventoryActionSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final controller = ref.read(receiptInputControllerProvider.notifier);
    final isCameraEnabled = controller.isCameraSupported;

    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return InventoryReceiptActionsSheet(
          isCameraEnabled: isCameraEnabled,
          onScanCameraTap: () {
            sheetContext.pop();
            unawaited(
              _handleReceiptInput(
                context: context,
                ref: ref,
                l10n: l10n,
                source: ReceiptInputSource.camera,
              ),
            );
          },
          onUploadFileTap: () {
            sheetContext.pop();
            unawaited(
              _handleReceiptInput(
                context: context,
                ref: ref,
                l10n: l10n,
                source: ReceiptInputSource.file,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleReceiptInput({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required ReceiptInputSource source,
  }) async {
    final controller = ref.read(receiptInputControllerProvider.notifier);
    final result = switch (source) {
      ReceiptInputSource.camera => await controller.pickFromCamera(),
      ReceiptInputSource.file => await controller.pickFromFile(),
    };
    if (!context.mounted) return;

    final message = switch (result.status) {
      ReceiptInputStatus.selected => _selectedMessage(source, l10n),
      ReceiptInputStatus.failed => l10n.inventoryReceiptSelectionFailed,
      ReceiptInputStatus.unsupported => l10n.inventoryActionCameraUnsupported,
      ReceiptInputStatus.canceled => null,
    };
    if (message == null) return;

    _showSnackBar(context, message);
  }

  String _selectedMessage(ReceiptInputSource source, AppLocalizations l10n) {
    if (source == ReceiptInputSource.camera) {
      return l10n.inventoryReceiptSelectedCamera;
    }
    return l10n.inventoryReceiptSelectedFile;
  }

  void _showSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
