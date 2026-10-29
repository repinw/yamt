import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Outlined "Heute" pill on the right of the diary top bar, shown while
/// another day is selected; a tap selects today.
class DiaryTodayButton extends StatelessWidget {
  /// Creates the button.
  const new({required this.onPressed, super.key});

  /// Key of the button, for tests.
  static const buttonKey = ValueKey<String>('diary-today-button');

  /// Called to select today.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);

    return Semantics(
      button: true,
      label: l10n.diaryJumpToTodayAction,
      onTap: onPressed,
      excludeSemantics: true,
      child: AppInkWell(
        key: buttonKey,
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSizes.minTapTarget,
            minHeight: AppSizes.minTapTarget,
          ),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: StadiumBorder(
                  side: BorderSide(
                    color: colors.track,
                    width: AppBudgetCard.chipOutline,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppBudgetCard.chip,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      l10n.diaryTodayTitle,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
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
