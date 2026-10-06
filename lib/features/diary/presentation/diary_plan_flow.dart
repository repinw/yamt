import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_plan_controller.dart';
import 'package:yamt/features/diary/presentation/diary_plan_details_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the details of [plan] and runs what the user picks there. With
/// [canAccept] the plan's day has come, so it can be eaten.
Future<void> openDiaryPlanFlow(
  BuildContext context,
  WidgetRef ref, {
  required CalorieEntry plan,
  required bool canAccept,
}) async {
  final action = await Navigator.of(context, rootNavigator: true)
      .push<DiaryPlanDetailsAction>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) =>
              DiaryPlanDetailsPage(plan: plan, canAccept: canAccept),
        ),
      );
  if (!context.mounted) {
    return;
  }
  switch (action) {
    case DiaryPlanDetailsAction.accept:
      await acceptDiaryPlanFlow(context, ref, plan: plan);
    case DiaryPlanDetailsAction.remove:
      await deleteDiaryPlanFlow(context, ref, plan: plan);
    case null:
      return;
  }
}

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

/// Eats [plan] as planned and offers undo in a snack bar.
Future<void> acceptDiaryPlanFlow(
  BuildContext context,
  WidgetRef ref, {
  required CalorieEntry plan,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  final container = ProviderScope.containerOf(context, listen: false);
  final controller = ref.read(diaryPlanControllerProvider.notifier);
  // The row stays until the plans reload; a second tap must not eat twice.
  if (controller.isAccepted(plan)) {
    return;
  }
  final result = await controller.accept(plan);
  if (result == null) {
    messenger.showAppSnackBar(
      l10n.diaryPlanAcceptFailed,
      tone: AppSnackBarTone.error,
    );
    return;
  }
  final entry = result.entry;
  messenger.showAppSnackBar(
    result.missedStock
        ? l10n.diaryPlanAcceptedWithoutStock
        : l10n.diaryPlanAccepted,
    onUndo: () => container
        .read(diaryPlanControllerProvider.notifier)
        .undoAccept(entry, plan),
  );
}
