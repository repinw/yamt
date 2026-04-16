import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _discardReasonDialogLogName = 'InventoryDiscardReasonDialog';

/// Show inventory discard reason dialog.
Future<InventoryDiscardReason?> showInventoryDiscardReasonDialog(
  BuildContext context, {
  bool useRootNavigator = false,
}) {
  final l10n = AppLocalizations.of(context)!;
  log(
    'showInventoryDiscardReasonDialog(): opening',
    name: _discardReasonDialogLogName,
  );

  return showDialog<InventoryDiscardReason>(
    context: context,
    useRootNavigator: useRootNavigator,
    builder: (dialogContext) {
      return SimpleDialog(
        title: Text(l10n.inventoryDiscardReasonTitle),
        children: [
          for (final reason in InventoryDiscardReason.values)
            SimpleDialogOption(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                log(
                  'showInventoryDiscardReasonDialog(): selected ${reason.name}',
                  name: _discardReasonDialogLogName,
                );
                Navigator.of(
                  dialogContext,
                  rootNavigator: useRootNavigator,
                ).pop(reason);
              },
              child: Text(reason.localizedLabel(l10n)),
            ),
        ],
      );
    },
  );
}
