import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_plan_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Deletes [plan] and offers undo in a snack bar.
Future<void> deleteDiaryPlanFlow(
  BuildContext context,
  WidgetRef ref, {
  required CalorieEntry plan,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  // The undo may come after the row is gone, so it reads the controller from
  // the container then.
  final container = ProviderScope.containerOf(context, listen: false);
  if (!await ref.read(diaryPlanControllerProvider.notifier).delete(plan)) {
    messenger.showAppSnackBar(
      l10n.diaryPlanDeleteFailed,
      tone: AppSnackBarTone.error,
    );
    return;
  }
  messenger.showAppSnackBar(
    l10n.diaryPlanDeleted,
    // A false result shows the undo failure snack bar.
    onUndo: () =>
        container.read(diaryPlanControllerProvider.notifier).restore(plan),
  );
}
