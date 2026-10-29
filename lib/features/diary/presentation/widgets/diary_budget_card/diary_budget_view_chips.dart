import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_after_plan_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_details_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The "Details" and "Nach Plan" buttons under the kcal line, as round
/// icons where the kcal column has room next to the taller macros.
class DiaryBudgetViewChips extends ConsumerWidget {
  /// Creates the chips.
  const new({required this.showAfterPlan, super.key});

  /// Whether the day has open plans, so "Nach Plan" can count them.
  final bool showAfterPlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);

    // The 48 wide tap areas already leave a gap between the buttons.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconToggle(
          key: DiaryBudgetCardKeys.detailsChip,
          icon: Icons.format_list_bulleted_rounded,
          label: l10n.diaryBudgetDetailsButtonLabel,
          selected: ref.watch(diaryBalanceDetailsControllerProvider),
          selectedColor: colors.ink,
          onTap: () =>
              ref.read(diaryBalanceDetailsControllerProvider.notifier).toggle(),
        ),
        if (showAfterPlan)
          _IconToggle(
            key: DiaryBudgetCardKeys.afterPlanChip,
            icon: Icons.event_available_rounded,
            label: l10n.diaryBalanceAfterPlanChip,
            selected: ref.watch(diaryAfterPlanControllerProvider),
            selectedColor: colors.plan,
            onTap: () =>
                ref.read(diaryAfterPlanControllerProvider.notifier).toggle(),
          ),
      ],
    );
  }
}

/// A round outlined icon button that fills with [selectedColor] when on;
/// [label] is for screen readers. Its tap area is 48 around the button.
class _IconToggle extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);

    return Semantics(
      button: true,
      toggled: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: AppInkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: AppSizes.minTapTarget,
          child: Center(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: selected ? selectedColor : Colors.transparent,
                shape: CircleBorder(
                  side: BorderSide(
                    color: selected ? selectedColor : colors.track,
                    width: AppBudgetCard.chipOutline,
                  ),
                ),
              ),
              child: SizedBox.square(
                dimension: AppBudgetCard.dayButton,
                child: Icon(
                  icon,
                  size: AppBudgetCard.dayIcon,
                  color: selected ? colors.tile : colors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
