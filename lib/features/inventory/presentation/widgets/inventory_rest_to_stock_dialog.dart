import 'package:material_ui/material_ui.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Key of the button that puts the rest into the Vorrat.
const inventoryRestToStockYesKey = Key('inventory_rest_to_stock_yes');

/// Asks whether the [rest] of a package that was not eaten goes into the
/// Vorrat. Returns true for yes; no and a dismissed dialog keep the old way,
/// in which only the eaten amount is saved.
Future<bool> showInventoryRestToStockDialog(
  BuildContext context, {
  required String rest,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final keepsRest = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: Text(l10n.inventoryRestToStockQuestion(rest)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.inventoryRestToStockNo),
        ),
        FilledButton(
          key: inventoryRestToStockYesKey,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.inventoryRestToStockYes),
        ),
      ],
    ),
  );
  return keepsRest ?? false;
}
