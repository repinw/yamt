import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Tap target opening the budget details sheet.
class DiaryDailyBudgetDetailsButton extends StatelessWidget {
  /// Creates the budget details trigger button.
  const new({required this.onTap, super.key});

  /// Called when the button is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final buttonColor = FoodLabelColors.of(context).accentText;

    return Semantics(
      button: true,
      label: l10n.diaryBudgetDetailsTitle,
      child: Material(
        type: MaterialType.transparency,
        child: AppInkWell(
          key: DiaryBalanceCardKeys.dailyBudgetDetailsButton,
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
            child: Center(
              widthFactor: 1,
              child: Text(
                l10n.diaryBudgetDetailsButtonLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFamily: AppFonts.mono,
                  color: buttonColor,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: buttonColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
