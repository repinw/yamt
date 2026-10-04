import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_previous_day_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Closes [day], so the day after it counts like a started day with the
/// carryover of [day], and offers undo in a snack bar.
Future<void> closeDiaryPreviousDayFlow(
  BuildContext context,
  WidgetRef ref, {
  required DateTime day,
  required String weekday,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  // The undo may come after the card is gone, so it reads the controller
  // from the container then.
  final container = ProviderScope.containerOf(context, listen: false);
  // A second tap before the card shows the close saves it again and
  // replaces the snack bar.
  if (!await ref.read(diaryPreviousDayControllerProvider.notifier).close(day)) {
    _showFailed(messenger, l10n.diaryPreviousDayCloseFailed(weekday));
    return;
  }
  messenger.showAppSnackBar(
    l10n.diaryPreviousDayClosed(weekday),
    // A false result shows the undo failure snack bar.
    onUndo: () =>
        container.read(diaryPreviousDayControllerProvider.notifier).reopen(),
  );
}

/// Opens the closed day before a planned day again.
Future<void> reopenDiaryPreviousDayFlow(
  BuildContext context,
  WidgetRef ref, {
  required String weekday,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  if (!await ref.read(diaryPreviousDayControllerProvider.notifier).reopen()) {
    _showFailed(messenger, l10n.diaryPreviousDayReopenFailed(weekday));
  }
}

void _showFailed(ScaffoldMessengerState messenger, String message) {
  messenger.showAppSnackBar(message, tone: AppSnackBarTone.error);
}
