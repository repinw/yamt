import 'package:material_ui/material_ui.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Key of the button that confirms the discard.
const freeCookingDiscardKey = ValueKey<String>('free-cooking-discard');

/// Asks whether to discard the rows of the "Frei kochen" page, or with
/// [body] another meal. Returns whether the cook confirmed.
Future<bool> showFreeCookingDiscardDialog(
  BuildContext context, {
  String? body,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final discard = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.freeCookingDiscardTitle),
      content: Text(body ?? l10n.freeCookingDiscardBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          key: freeCookingDiscardKey,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.freeCookingDiscardAction),
        ),
      ],
    ),
  );
  return discard ?? false;
}
