import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _discardReasonDialogLogName = 'InventoryDiscardReasonDialog';

Future<InventoryDiscardReason?> showInventoryDiscardReasonDialog(
  BuildContext context,
) {
  final l10n = AppLocalizations.of(context)!;

  return showDialog<InventoryDiscardReason>(
    context: context,
    builder: (dialogContext) {
      return SimpleDialog(
        title: Text(l10n.inventoryDiscardReasonTitle),
        children: [
          for (final reason in InventoryDiscardReason.values)
            SimpleDialogOption(
              onPressed: () {
                log(
                  'showInventoryDiscardReasonDialog(): selected ${reason.name}',
                  name: _discardReasonDialogLogName,
                );
                Navigator.of(dialogContext).pop(reason);
              },
              child: Text(reason.localizedLabel(l10n)),
            ),
        ],
      );
    },
  );
}
