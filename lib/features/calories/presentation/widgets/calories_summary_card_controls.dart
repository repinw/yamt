import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_summary_view_mode_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Toggles the diary summary between balance and classic modes.
class SummaryModeToggle extends StatelessWidget {
  /// Creates the summary mode toggle.
  const SummaryModeToggle({
    required this.viewMode,
    required this.onChanged,
    super.key,
  });

  /// Currently selected summary mode.
  final CalorieSummaryViewMode viewMode;

  /// Callback invoked when the user selects another mode.
  final Future<void> Function(CalorieSummaryViewMode mode) onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        key: CaloriesPageKeys.summaryModeToggle,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: AppInventoryEditorialSurfaces.ghostBorder(colors),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SummaryModeChip(
                label: l10n.caloriesSummaryViewBalance,
                isSelected: viewMode == CalorieSummaryViewMode.balance,
                onTap: () => onChanged(CalorieSummaryViewMode.balance),
                textKey: CaloriesPageKeys.summaryModeOption(
                  CalorieSummaryViewMode.balance.name,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              SummaryModeChip(
                label: l10n.caloriesSummaryViewClassic,
                isSelected: viewMode == CalorieSummaryViewMode.classic,
                onTap: () => onChanged(CalorieSummaryViewMode.classic),
                textKey: CaloriesPageKeys.summaryModeOption(
                  CalorieSummaryViewMode.classic.name,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One selectable chip inside the summary mode toggle.
class SummaryModeChip extends StatelessWidget {
  /// Creates a summary mode chip.
  const SummaryModeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.textKey,
    super.key,
  });

  /// Text shown inside the chip.
  final String label;

  /// Whether the chip is currently selected.
  final bool isSelected;

  /// Callback invoked when the chip is tapped.
  final VoidCallback onTap;

  /// Key used by widget tests to find the chip label.
  final Key textKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.onSurface.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            key: textKey,
            style: textTheme.labelMedium?.copyWith(
              color: isSelected ? colors.primary : colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
