import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/inventory_eat_flow_leading_icon.dart';

/// Shared date card.
class InventoryEatFlowWhenCard extends StatelessWidget {
  /// Creates date card.
  const InventoryEatFlowWhenCard({
    required this.label,
    required this.isToday,
    required this.buttonKey,
    required this.compactKey,
    required this.labeledKey,
    required this.onPressed,
    super.key,
  });

  /// Label.
  final String? label;

  /// Whether today.
  final bool isToday;

  /// Button key.
  final Key buttonKey;

  /// Compact key.
  final Key compactKey;

  /// Labeled key.
  final Key labeledKey;

  /// Press callback.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasLabel = !isToday && label != null;

    return Material(
      color: Colors.transparent,
      child: AppInkWell(
        key: buttonKey,
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppEditorialSurfaces.ghostBorder(colors),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 66),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: hasLabel
                  ? Row(
                      key: labeledKey,
                      children: [
                        const InventoryEatFlowLeadingIcon(
                          icon: Icons.calendar_today_rounded,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            label!,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    )
                  : Row(
                      key: compactKey,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const InventoryEatFlowLeadingIcon(
                          icon: Icons.calendar_today_rounded,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
