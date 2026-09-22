import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Notice box explaining automated calculation of carbohydrates budget.
class SettingsMacroGoalsCarbsNotice extends StatelessWidget {
  /// Creates the carbs notice box.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accents = MetricAccentColors.of(context);
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accents.carbs.withValues(
          alpha: colors.brightness == Brightness.dark ? 0.14 : 0.08,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accents.carbs.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 18, color: accents.carbs),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.settingsMacroGoalsCarbsAutoLabel,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
