import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_expand_indicator.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/brand_badge.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/remaining_progress_bar.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/status_line.dart';

/// Defines inventory tile header layout.
class InventoryTileHeaderLayout extends StatelessWidget {
  /// The inventory tile header layout.
  const InventoryTileHeaderLayout({
    required this.leading,
    required this.title,
    required this.progressRatio,
    required this.progressLabel,
    required this.segmentedByUnits,
    required this.totalUnits,
    required this.remainingUnits,
    required this.isExpanded,
    super.key,
    this.titleStyle,
    this.badgeText,
    this.statusText,
    this.statusColor,
    this.action,
    this.showSelectionCheckbox = false,
    this.isSelected = false,
    this.showExpandIndicator = true,
    this.expandIndicatorEnabled = true,
    this.expandIndicatorKey,
  });

  /// The leading.
  final Widget leading;

  /// The title.
  final String title;

  /// The title style.
  final TextStyle? titleStyle;

  /// The badge text.
  final String? badgeText;

  /// The status text.
  final String? statusText;

  /// The status color.
  final Color? statusColor;

  /// The progress ratio.
  final double progressRatio;

  /// The progress label.
  final String progressLabel;

  /// The segmented by units.
  final bool segmentedByUnits;

  /// The total units.
  final int totalUnits;

  /// The remaining units.
  final num remainingUnits;

  /// The action.
  final Widget? action;

  /// The show selection checkbox.
  final bool showSelectionCheckbox;

  /// Whether selected.
  final bool isSelected;

  /// The show expand indicator.
  final bool showExpandIndicator;

  /// Whether expanded.
  final bool isExpanded;

  /// The expand indicator enabled.
  final bool expandIndicatorEnabled;

  /// The expand indicator key.
  final Key? expandIndicatorKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSelectionCheckbox) ...[
          IgnorePointer(
            child: Checkbox(
              value: isSelected,
              onChanged: (_) {},
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _InventoryTileHeaderInfo(
                      title: title,
                      titleStyle: titleStyle,
                      badgeText: badgeText,
                      statusText: statusText,
                      statusColor: statusColor,
                    ),
                  ),
                  if (showExpandIndicator) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _buildExpandIndicator(),
                  ],
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: RemainingProgressBar(
                      ratio: progressRatio,
                      stockLabel: progressLabel,
                      segmentedByUnits: segmentedByUnits,
                      totalUnits: totalUnits,
                      remainingUnits: remainingUnits,
                      labelLayout: RemainingProgressBarLabelLayout.aboveBar,
                      trackColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    action!,
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandIndicator() {
    return InventoryExpandIndicator(
      isExpanded: isExpanded,
      enabled: expandIndicatorEnabled,
      rotationKey: expandIndicatorKey,
    );
  }
}

class _InventoryTileHeaderInfo extends StatelessWidget {
  const _InventoryTileHeaderInfo({
    required this.title,
    required this.titleStyle,
    required this.badgeText,
    required this.statusText,
    required this.statusColor,
  });

  final String title;
  final TextStyle? titleStyle;
  final String? badgeText;
  final String? statusText;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final hasBadge = badgeText != null && badgeText!.trim().isNotEmpty;
    final hasStatus =
        statusText != null &&
        statusText!.trim().isNotEmpty &&
        statusColor != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasBadge) ...[
          BrandBadge(brand: badgeText!),
          const SizedBox(height: AppSpacing.xxs),
        ],
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style:
              titleStyle ??
              Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (hasStatus) ...[
          const SizedBox(height: AppSpacing.xxs),
          StatusLine(text: statusText!, color: statusColor!),
        ],
      ],
    );
  }
}
