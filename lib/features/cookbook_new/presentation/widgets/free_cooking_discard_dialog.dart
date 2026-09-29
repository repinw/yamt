import 'package:material_ui/material_ui.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Asks whether to discard the rows of the "Frei kochen" page. Returns
/// whether the cook confirmed.
Future<bool> showFreeCookingDiscardDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final discard = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.freeCookingDiscardTitle),
      content: Text(l10n.freeCookingDiscardBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.freeCookingDiscardAction),
        ),
      ],
    ),
  );
  return discard ?? false;
}
