import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_labels.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Logged day picker button in the calorie entry details sheet.
class CalorieEntryLoggedDayButton extends StatelessWidget {
  /// Creates a logged day picker button.
  const CalorieEntryLoggedDayButton({
    required this.loggedAt,
    required this.isEnabled,
    required this.onPressed,
    required this.material,
    super.key,
  });

  /// Day/time currently selected for the entry.
  final DateTime loggedAt;

  /// Whether the button can be tapped.
  final bool isEnabled;

  /// Called when the user taps the button.
  final VoidCallback onPressed;

  /// Material localizations used for date formatting.
  final MaterialLocalizations material;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final foregroundColor = isEnabled
        ? colors.onSurface
        : colors.onSurface.withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        enableFeedback: false,
        key: CalorieEntryDetailKeys.loggedDayButton,
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  calorieEntryLoggedDayLabel(l10n, material, loggedAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: isEnabled ? colors.onSurfaceVariant : foregroundColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
