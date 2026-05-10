import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Header for the calorie entry details sheet chrome.
class CalorieEntryDetailsSheetHeader extends StatelessWidget {
  /// Creates a details sheet header.
  const CalorieEntryDetailsSheetHeader({
    required this.title,
    required this.closeTooltip,
    required this.isSaving,
    required this.onClose,
    super.key,
  });

  /// Header title.
  final String title;

  /// Tooltip shown on the close button.
  final String closeTooltip;

  /// Whether closing is currently disabled.
  final bool isSaving;

  /// Called when closing the sheet.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 6,
            decoration: BoxDecoration(
              color: colors.outlineVariant.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: isSaving ? null : onClose,
                tooltip: closeTooltip,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: colors.surfaceContainerHighest.withValues(
                    alpha: 0.92,
                  ),
                ),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
