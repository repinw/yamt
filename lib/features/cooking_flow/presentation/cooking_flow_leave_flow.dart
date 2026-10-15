import 'dart:developer';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Key of "Erneut versuchen" in the dialog after a failed save.
const cookflowLeaveRetryKey = ValueKey<String>('cookflow-leave-retry');

/// Key of "Ohne Speichern verlassen" in the dialog after a failed save.
const cookflowLeaveUnsavedKey = ValueKey<String>('cookflow-leave-unsaved');

enum _LeaveChoice { retry, leave }

/// Saves the cooking session with [save] before the cook leaves. When the
/// save fails or throws, a dialog offers to try again or to leave without
/// saving. Returns whether the cook may leave; dismissing the dialog stays.
Future<bool> saveBeforeLeavingCookflow(
  BuildContext context,
  Future<bool> Function() save,
) async {
  while (!await _trySave(save)) {
    if (!context.mounted) {
      return false;
    }
    final choice = await _showSaveFailedDialog(context);
    if (choice != _LeaveChoice.retry) {
      return choice == _LeaveChoice.leave;
    }
  }
  return true;
}

Future<bool> _trySave(Future<bool> Function() save) async {
  try {
    return await save();
  } on Object catch (error, stackTrace) {
    // The dialog shows the failure; the log keeps its cause.
    log(
      'Failed to save the cookflow session.',
      name: 'cooking_flow',
      error: error,
      stackTrace: stackTrace,
    );
    return false;
  }
}

Future<_LeaveChoice?> _showSaveFailedDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<_LeaveChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.cookflowLeaveUnsavedTitle),
      content: Text(l10n.cookflowLeaveUnsavedBody),
      actions: [
        TextButton(
          key: cookflowLeaveUnsavedKey,
          onPressed: () => Navigator.of(context).pop(_LeaveChoice.leave),
          child: Text(l10n.cookflowLeaveUnsavedAction),
        ),
        TextButton(
          key: cookflowLeaveRetryKey,
          onPressed: () => Navigator.of(context).pop(_LeaveChoice.retry),
          child: Text(l10n.cookflowLeaveRetryAction),
        ),
      ],
    ),
  );
}
