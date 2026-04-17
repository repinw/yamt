import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_action_picker_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _discardReasonDialogLogName = 'InventoryDiscardReasonDialog';

/// Show inventory discard reason dialog.
Future<InventoryDiscardReason?> showInventoryDiscardReasonDialog(
  BuildContext context, {
  String? itemName,
  bool useRootNavigator = true,
}) {
  log(
    'showInventoryDiscardReasonDialog(): opening',
    name: _discardReasonDialogLogName,
  );

  return showInventoryActionPickerSheet<InventoryDiscardReason>(
    context,
    useRootNavigator: useRootNavigator,
    builder: (dialogContext) {
      return _InventoryDiscardReasonDialog(
        itemName: itemName,
        useRootNavigator: useRootNavigator,
      );
    },
  );
}

class _InventoryDiscardReasonDialog extends StatelessWidget {
  const _InventoryDiscardReasonDialog({
    required this.itemName,
    required this.useRootNavigator,
  });

  final String? itemName;
  final bool useRootNavigator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return InventoryActionPickerSheet(
      title: l10n.inventoryDiscardReasonTitle,
      subtitle: itemName,
      onClose: () => Navigator.of(
        context,
        rootNavigator: useRootNavigator,
      ).pop(),
      footer: Center(
        child: TextButton(
          onPressed: () => Navigator.of(
            context,
            rootNavigator: useRootNavigator,
          ).pop(),
          child: Text(l10n.inventoryReceiptReviewCancelAction),
        ),
      ),
      children: [
        for (final reason in InventoryDiscardReason.values) ...[
          _InventoryDiscardReasonOption(
            icon: _reasonIcon(reason),
            title: reason.localizedLabel(l10n),
            foregroundColor: _reasonForegroundColor(colors, reason),
            backgroundColor: _reasonBackgroundColor(colors, reason),
            onPressed: () => _close(context, reason),
          ),
          if (reason != InventoryDiscardReason.values.last)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  void _close(BuildContext context, InventoryDiscardReason reason) {
    FocusManager.instance.primaryFocus?.unfocus();
    log(
      'showInventoryDiscardReasonDialog(): selected ${reason.name}',
      name: _discardReasonDialogLogName,
    );
    Navigator.of(context, rootNavigator: useRootNavigator).pop(reason);
  }

  IconData _reasonIcon(InventoryDiscardReason reason) {
    return switch (reason) {
      InventoryDiscardReason.expired => Icons.event_busy_outlined,
      InventoryDiscardReason.spoiled => Icons.delete_outline_rounded,
      InventoryDiscardReason.cookedTooMuch => Icons.soup_kitchen_outlined,
      InventoryDiscardReason.other => Icons.more_horiz_rounded,
    };
  }

  Color _reasonForegroundColor(
    ColorScheme colors,
    InventoryDiscardReason reason,
  ) {
    return switch (reason) {
      InventoryDiscardReason.expired => colors.error,
      InventoryDiscardReason.spoiled => colors.error,
      InventoryDiscardReason.cookedTooMuch => colors.primary,
      InventoryDiscardReason.other => colors.onSurfaceVariant,
    };
  }

  Color _reasonBackgroundColor(
    ColorScheme colors,
    InventoryDiscardReason reason,
  ) {
    return switch (reason) {
      InventoryDiscardReason.expired => colors.errorContainer.withValues(
        alpha: 0.34,
      ),
      InventoryDiscardReason.spoiled => colors.errorContainer.withValues(
        alpha: 0.48,
      ),
      InventoryDiscardReason.cookedTooMuch =>
        colors.primaryContainer.withValues(alpha: 0.42),
      InventoryDiscardReason.other => colors.surfaceContainerHigh,
    };
  }
}

class _InventoryDiscardReasonOption extends StatelessWidget {
  const _InventoryDiscardReasonOption({
    required this.icon,
    required this.title,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final Color foregroundColor;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              InventoryActionPickerOptionIcon(
                icon: icon,
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
