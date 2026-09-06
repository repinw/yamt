import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Tap target opening the budget details sheet.
class DiaryDailyBudgetDetailsButton extends StatelessWidget {
  /// Creates the budget details trigger button.
  const DiaryDailyBudgetDetailsButton({
    required this.onTap,
    required this.isHeartDay,
    super.key,
  });

  /// Called when the button is tapped.
  final VoidCallback onTap;

  /// Whether the card represents a heart day.
  final bool isHeartDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final accents = MetricAccentColors.of(context);
    final buttonColor = isHeartDay
        ? accents.heartFor(colors.brightness)
        : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      label: l10n.diaryBudgetDetailsTitle,
      child: Material(
        type: MaterialType.transparency,
        child: AppInkWell(
          key: DiaryBalanceCardKeys.dailyBudgetDetailsButton,
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.diaryBudgetDetailsButtonLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: buttonColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: buttonColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
