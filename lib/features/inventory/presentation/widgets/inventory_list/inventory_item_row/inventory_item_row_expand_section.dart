import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_view_data.dart';

class InventoryItemRowExpandSection extends StatelessWidget {
  const InventoryItemRowExpandSection({
    super.key,
    required this.isExpanded,
    required this.viewData,
    required this.colorScheme,
    required this.deleteLabel,
    required this.throwAwayLabel,
    required this.onDeletePressed,
    required this.onThrowAwayPressed,
    required this.onToggleExpanded,
  });

  final bool isExpanded;
  final InventoryItemRowViewData viewData;
  final ColorScheme colorScheme;
  final String deleteLabel;
  final String throwAwayLabel;
  final VoidCallback onDeletePressed;
  final VoidCallback? onThrowAwayPressed;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          height: InventoryItemRowConstants.expandSectionTopSpacing,
        ),
        SizedBox(
          width: double.infinity,
          height: InventoryItemRowConstants.expandIndicatorHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: viewData.rowBorderColor.withValues(alpha: 0.6),
                ),
              ),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: InkWell(
                onTap: onToggleExpanded,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: InventoryItemRowConstants.expandIndicatorTopPadding,
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: isExpanded ? math.pi : 0),
                    duration: InventoryItemRowConstants.expandArrowDuration,
                    curve: Curves.easeOutCubic,
                    child: Transform.scale(
                      scaleX: 1.4,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: viewData.expandHintColor,
                      ),
                    ),
                    builder: (context, angle, child) {
                      return Transform.rotate(angle: angle, child: child);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: isExpanded ? 1.0 : 0.0),
          duration: InventoryItemRowConstants.expandPanelDuration,
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.only(
              top: InventoryItemRowConstants.actionPanelTopSpacing,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewData.unitPriceLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDeletePressed,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(deleteLabel),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(
                            color: colorScheme.error.withValues(alpha: 0.45),
                          ),
                          minimumSize: const Size(
                            0,
                            InventoryItemRowConstants.actionButtonHeight,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: onThrowAwayPressed,
                        icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                        label: Text(throwAwayLabel),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(
                            0,
                            InventoryItemRowConstants.actionButtonHeight,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          builder: (context, value, child) {
            if (value == 0) {
              return const SizedBox.shrink();
            }

            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: value,
                child: Opacity(opacity: value, child: child),
              ),
            );
          },
        ),
      ],
    );
  }
}
