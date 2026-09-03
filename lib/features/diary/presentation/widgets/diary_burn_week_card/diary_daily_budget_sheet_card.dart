import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';

/// Styled card container for daily budget details sheet sections.
class DiaryDailyBudgetSheetCard extends StatelessWidget {
  /// Creates a styled sheet card.
  const DiaryDailyBudgetSheetCard({
    required this.child,
    super.key,
  });

  /// Card body widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: AppEditorialSurfaces.liftedCard(colors),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: child,
    );
  }
}

/// Key-value row inside daily budget detail sections.
class DiaryDailyBudgetRow extends StatelessWidget {
  /// Creates a budget row.
  const DiaryDailyBudgetRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
    this.isHighlight = false,
    super.key,
  });

  /// Row label text.
  final String label;

  /// Formatted value string.
  final String value;

  /// Optional value color override.
  final Color? valueColor;

  /// Whether label and value should use bold typography.
  final bool isBold;

  /// Whether this row is the primary visual highlight (e.g. left today).
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).colorScheme;

    final labelStyle = isHighlight
        ? theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800)
        : (isBold
            ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)
            : theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ));

    final valueStyle = isHighlight
        ? theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: valueColor ?? colors.onSurface,
          )
        : (isBold
            ? theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor ?? colors.onSurface,
              )
            : theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ?? colors.onSurface,
              ));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: labelStyle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
