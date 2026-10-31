import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_labels.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The day type buttons with their tap padding: only [AppBudgetCard.dayTypeGap]
/// shows between them, the rest of each 48 wide tap reaches outward.
const List<(DiaryDayType, EdgeInsetsDirectional)> _dayTypeButtons = [
  (
    DiaryDayType.training,
    EdgeInsetsDirectional.only(
      start: AppBudgetCard.dayTypeHitOverhang,
      end: AppBudgetCard.dayTypeGap / 2,
    ),
  ),
  (
    DiaryDayType.pause,
    EdgeInsetsDirectional.only(
      start: AppBudgetCard.dayTypeGap / 2,
      end: AppBudgetCard.dayTypeHitOverhang,
    ),
  ),
];

/// The training and pause buttons; a tap on the pressed one goes back to a
/// normal day.
class DiaryBudgetDayTypeButtons extends StatelessWidget {
  /// Creates the buttons.
  const new({required this.selected, required this.onSelect, super.key});

  /// Type of the day.
  final DiaryDayType selected;

  /// Called with the type the day becomes.
  final ValueChanged<DiaryDayType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (type, hitPadding) in _dayTypeButtons)
          _DayTypeButton(
            type: type,
            hitPadding: hitPadding,
            selected: selected == type,
            onTap: () =>
                onSelect(selected == type ? DiaryDayType.normal : type),
          ),
      ],
    );
  }
}

/// Round training or pause button; pressed, it widens and shows its word.
/// [hitPadding] widens the tap area past the visible button.
class _DayTypeButton extends StatelessWidget {
  const new({
    required this.type,
    required this.hitPadding,
    required this.selected,
    required this.onTap,
  });

  final DiaryDayType type;
  final EdgeInsetsDirectional hitPadding;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final foreground = selected ? colors.tile : colors.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: diaryDayTypeLabel(type, l10n),
      onTap: onTap,
      excludeSemantics: true,
      child: AppInkWell(
        key: DiaryBudgetCardKeys.dayTypeButton(type),
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: hitPadding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
            child: Center(
              widthFactor: 1,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: selected ? colors.ink : colors.paper,
                  shape: const StadiumBorder(),
                ),
                child: Padding(
                  padding: selected
                      ? const EdgeInsetsDirectional.only(
                          start: AppSpacing.xs,
                          end: AppSpacing.md,
                        )
                      : EdgeInsets.zero,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppBudgetCard.dayButton,
                      minHeight: AppBudgetCard.dayButton,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: AppSpacing.xxs,
                      children: [
                        Icon(
                          diaryBudgetDayTypeIcon(type),
                          size: AppBudgetCard.dayIcon,
                          color: foreground,
                        ),
                        if (selected)
                          Text(
                            diaryDayTypeShortLabel(type, l10n),
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  fontFamily: AppFonts.geist,
                                  fontWeight: FontWeight.w600,
                                  color: foreground,
                                ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon of a day type in the budget card.
IconData diaryBudgetDayTypeIcon(DiaryDayType type) => switch (type) {
  DiaryDayType.training => Icons.fitness_center_rounded,
  DiaryDayType.normal => Icons.radio_button_unchecked_rounded,
  DiaryDayType.pause => Icons.pause_rounded,
};
