import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Übrig | Gegessen": whether the card's numbers show what is left or what
/// was eaten. Each segment's tap area is 48 high around the 36 high track.
class DiaryBudgetViewSwitch extends StatelessWidget {
  /// Creates the switch.
  const new({required this.showEaten, required this.onSelect, super.key});

  /// Whether "Gegessen" is selected.
  final bool showEaten;

  /// Called with true for "Gegessen", false for "Übrig".
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: (AppSizes.minTapTarget - AppBudgetCard.viewSwitch) / 2,
            ),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: colors.paper,
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppBudgetCard.viewSwitchInset,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (eaten, label) in [
                (false, l10n.diaryBudgetViewLeft),
                (true, l10n.diaryBudgetViewEaten),
              ])
                _ViewSegment(
                  key: DiaryBudgetCardKeys.viewSegment(eaten: eaten),
                  label: label,
                  selected: showEaten == eaten,
                  onTap: () => onSelect(eaten),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ViewSegment extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);

    return Semantics(
      button: true,
      selected: selected,
      onTap: onTap,
      child: AppInkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: selected ? colors.tile : Colors.transparent,
                shape: const StadiumBorder(),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight:
                        AppBudgetCard.viewSwitch -
                        2 * AppBudgetCard.viewSwitchInset,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontFamily: AppFonts.geist,
                        fontWeight: FontWeight.w600,
                        color: selected ? colors.ink : colors.muted,
                      ),
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
