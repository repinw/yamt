import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_entry_label_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_action_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_components_list.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What the user chose on the plan details page.
enum DiaryPlanDetailsAction {
  /// Eat the plan as planned.
  accept,

  /// Remove the plan.
  remove,
}

/// Details of a plan, in the food label look of the entry details.
///
/// Pops with the chosen [DiaryPlanDetailsAction], or null on close. The
/// caller runs it, so its snack bar shows on the diary.
class DiaryPlanDetailsPage extends StatelessWidget {
  /// Creates the page for [plan].
  const new({required this.plan, required this.canAccept, super.key});

  /// Key of the button that eats the plan.
  static const acceptButtonKey = Key('diary_plan_details_accept_button');

  /// Key of the line that removes the plan.
  static const removeKey = Key('diary_plan_details_remove');

  /// Key of the close button.
  static const closeButtonKey = Key('diary_plan_details_close_button');

  /// The plan.
  final CalorieEntry plan;

  /// Whether the plan's day has come, so it can be eaten.
  final bool canAccept;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    void pop(DiaryPlanDetailsAction action) =>
        Navigator.of(context).pop(action);
    return EatPageScaffold(
      whenControl: const SizedBox.shrink(),
      kcal: plan.totalKcal,
      confirmLabel: l10n.diaryPlanAcceptAction,
      confirmButtonKey: acceptButtonKey,
      onConfirm: canAccept ? () => pop(DiaryPlanDetailsAction.accept) : null,
      confirmHint: canAccept ? null : l10n.diaryPlanAcceptLaterHint,
      cancelButtonKey: closeButtonKey,
      children: [
        DiaryEntryLabelSection(entry: plan),
        if (plan.isBundle)
          EatComponentsList(
            initiallyExpanded: true,
            components: [
              for (final food in plan.bundleComponents)
                (
                  name: food.name,
                  amount: food.amountLabel,
                  kcal: food.totalKcal,
                ),
            ],
          ),
        EatActionCard(
          title: l10n.diaryPlanSemanticsLabel,
          actions: [
            (
              key: removeKey,
              icon: Icons.event_busy_rounded,
              label: l10n.diaryPlanRemoveAction,
              color: Theme.of(context).colorScheme.error,
              onPressed: () => pop(DiaryPlanDetailsAction.remove),
            ),
          ],
        ),
      ],
    );
  }
}
