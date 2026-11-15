import 'package:material_ui/material_ui.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Key of the button that confirms the discard.
const cookingDiscardKey = ValueKey<String>('free-cooking-discard');

/// Asks [title] before discarding, with [body] saying what that undoes.
/// Returns whether the cook confirmed.
Future<bool> showFreeCookingDiscardDialog(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final discard = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          key: cookingDiscardKey,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.cookingDiscardAction),
        ),
      ],
    ),
  );
  return discard ?? false;
}
