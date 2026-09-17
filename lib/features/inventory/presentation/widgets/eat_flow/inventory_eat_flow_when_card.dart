import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_field_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/inventory_eat_flow_leading_icon.dart';

/// Shared date card.
class InventoryEatFlowWhenCard extends StatelessWidget {
  /// Creates date card.
  const new({
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

    return AppFieldCard(
      tapTargetKey: buttonKey,
      onTap: onPressed,
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
    );
  }
}
