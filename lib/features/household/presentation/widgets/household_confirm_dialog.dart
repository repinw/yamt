import 'package:material_ui/material_ui.dart';

/// Asks the user to confirm a household action. Returns `true` on confirm.
Future<bool> showHouseholdConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) =>
        HouseholdConfirmDialog(title: title, message: message, action: action),
  );
  return confirmed ?? false;
}

/// A dialog that asks to confirm a household action.
class HouseholdConfirmDialog extends StatelessWidget {
  /// Creates the dialog.
  const new({
    required this.title,
    required this.message,
    required this.action,
    super.key,
  });

  /// Key of the confirm button.
  static const confirmKey = Key('household_confirm_action');

  /// The question.
  final String title;

  /// What happens.
  final String message;

  /// The label of the confirm button.
  final String action;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: confirmKey,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(action),
        ),
      ],
    );
  }
}
