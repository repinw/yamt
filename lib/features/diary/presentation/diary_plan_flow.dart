import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_plan_controller.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/diary_plan_details_page.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_copy_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_plan_days_sheet.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_plan_accept_service.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the details of [plan] and runs what the user picks there. With
/// [canAccept] the plan's day has come, so it can be eaten.
Future<void> openDiaryPlanFlow(
  BuildContext context,
  WidgetRef ref, {
  required CalorieEntry plan,
  required bool canAccept,
}) async {
  final today = ref.read(diaryCalendarControllerProvider).today;
  final action = await Navigator.of(context, rootNavigator: true)
      .push<DiaryPlanDetailsAction>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => DiaryPlanDetailsPage(
            plan: plan,
            canAccept: canAccept,
            today: today,
          ),
        ),
      );
  if (!context.mounted) {
    return;
  }
  switch (action) {
    case DiaryPlanAccept():
      await acceptDiaryPlanFlow(context, ref, plan: plan);
    case DiaryPlanRemove():
      await deleteDiaryPlanFlow(context, ref, plan: plan);
    case DiaryPlanCopy():
      await _copyDiaryPlanFlow(context, ref, plan: plan, today: today);
    case DiaryPlanChange(plan: final changed):
      await _changeDiaryPlanFlow(context, ref, plan: plan, changed: changed);
    case null:
      return;
  }
}

/// Asks for more days to plan the food of [plan] on, plans a copy on each,
/// and offers one undo for all of them.
Future<void> _copyDiaryPlanFlow(
  BuildContext context,
  WidgetRef ref, {
  required CalorieEntry plan,
  required DateTime today,
}) async {
  final choice = await showDiaryPlanDaysSheet(
    context: context,
    plan: plan,
    today: today,
  );
  if (choice == null || !context.mounted) {
    return;
  }
  await _planCopies(
    context,
    ref,
    entries: [plan],
    days: choice.days,
    mealType: choice.mealType,
  );
}

/// Asks which meals of [day] to copy as plans and on which days, plans the
/// copies, and offers one undo for all of them. [entries] are the eaten
/// foods and plans of [day]; [mealType] is ticked at first.
Future<void> copyDiaryMealFlow(
  BuildContext context,
  WidgetRef ref, {
  required DateTime day,
  required MealType mealType,
  required List<CalorieEntry> entries,
}) async {
  final choice = await showDiaryMealCopySheet(
    context: context,
    day: day,
    mealType: mealType,
    entries: entries,
    today: ref.read(diaryCalendarControllerProvider).today,
  );
  if (choice == null || !context.mounted) {
    return;
  }
  await _planCopies(context, ref, entries: choice.entries, days: choice.days);
}

/// Plans [entries] on [days], in [mealType] or their own meals, and offers
/// one undo for all copies.
Future<void> _planCopies(
  BuildContext context,
  WidgetRef ref, {
  required List<CalorieEntry> entries,
  required List<DateTime> days,
  MealType? mealType,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  final container = ProviderScope.containerOf(context, listen: false);
  final copies = await ref
      .read(diaryPlanControllerProvider.notifier)
      .copyToDays(entries, days: days, mealType: mealType);
  if (copies == null) {
    messenger.showAppSnackBar(
      l10n.diaryPlanCopyFailed,
      tone: AppSnackBarTone.error,
    );
    return;
  }
  messenger.showAppSnackBar(
    l10n.diaryPlanCopied(days.length),
    onUndo: () =>
        container.read(diaryPlanControllerProvider.notifier).deleteAll(copies),
  );
}

/// Saves [changed] in place of [plan], opens its day, and offers undo.
Future<void> _changeDiaryPlanFlow(
  BuildContext context,
  WidgetRef ref, {
  required CalorieEntry plan,
  required CalorieEntry changed,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  final container = ProviderScope.containerOf(context, listen: false);
  final controller = ref.read(diaryPlanControllerProvider.notifier);
  final toSave = await controller.withPlanStock(plan, changed);
  // An eaten plan is gone; saving it again would bring it back. It may have
  // been eaten from its row while the Vorrat loaded.
  if (controller.isAccepted(plan)) {
    return;
  }
  // The plan keeps its id, so saving it overwrites the old one.
  if (!await controller.plan(toSave)) {
    messenger.showAppSnackBar(
      l10n.diaryPlanChangeFailed,
      tone: AppSnackBarTone.error,
    );
    return;
  }
  messenger.showAppSnackBar(
    l10n.diaryPlanChanged,
    onUndo: () =>
        container.read(diaryPlanControllerProvider.notifier).plan(plan),
  );
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
      _isMealInPot(container)
          ? l10n.diaryPlanAcceptMealInPot
          : l10n.diaryPlanAcceptFailed,
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

/// Eats every plan of [plans] that is not eaten yet and offers one undo for
/// all of them.
Future<void> acceptAllDiaryPlansFlow(
  BuildContext context,
  WidgetRef ref, {
  required List<CalorieEntry> plans,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  final container = ProviderScope.containerOf(context, listen: false);
  final controller = ref.read(diaryPlanControllerProvider.notifier);
  final (:eaten, :failed) = await controller.acceptAll(plans);
  if (eaten.isEmpty) {
    if (failed > 0) {
      messenger.showAppSnackBar(
        l10n.diaryPlanAcceptFailed,
        tone: AppSnackBarTone.error,
      );
    }
    return;
  }
  final missedStock = eaten.any((it) => it.result.missedStock);
  messenger.showAppSnackBar(
    failed > 0
        ? l10n.diaryPlansAcceptedPartly(eaten.length, eaten.length + failed)
        : missedStock
        ? l10n.diaryPlansAcceptedWithoutStock(eaten.length)
        : l10n.diaryPlansAccepted(eaten.length),
    tone: failed > 0 ? AppSnackBarTone.error : AppSnackBarTone.success,
    onUndo: () async {
      final undo = container.read(diaryPlanControllerProvider.notifier);
      var undone = true;
      for (final (:plan, :result) in eaten) {
        undone = await undo.undoAccept(result.entry, plan) && undone;
      }
      return undone;
    },
  );
}

/// Whether the last accept failed because its meal is still in the pot.
bool _isMealInPot(ProviderContainer container) =>
    switch (container.read(diaryPlanControllerProvider).error) {
      InventoryPlanAcceptException(:final isMealInPot) => isMealInPot,
      _ => false,
    };
