import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

/// Renders the classic hero adjustment chips.
class ClassicSummaryAdjustmentsPill extends StatelessWidget {
  /// Creates the classic hero adjustment chip row.
  const ClassicSummaryAdjustmentsPill({
    required this.activityDeltaKcal,
    required this.carryoverKcal,
    required this.numberFormat,
    super.key,
  });

  /// Activity calories currently included in the classic target.
  final double activityDeltaKcal;

  /// Carryover calories currently included in the classic target.
  final double carryoverKcal;

  /// Number formatter used for localized chip values.
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (activityDeltaKcal.round() != 0)
        ClassicHeroAdjustmentBadge(
          icon: Icons.local_fire_department_outlined,
          color: const Color(0xFFF59E0B),
          value: activityDeltaKcal.round(),
          numberFormat: numberFormat,
        ),
      if (carryoverKcal.round() != 0)
        ClassicHeroAdjustmentBadge(
          icon: Icons.calendar_today_outlined,
          color: const Color(0xFF3B82F6),
          value: carryoverKcal.round(),
          numberFormat: numberFormat,
        ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < badges.length; index += 1) ...[
          if (index > 0) const SizedBox(width: AppSpacing.xs),
          badges[index],
        ],
      ],
    );
  }
}

/// Displays one colored adjustment chip in the classic hero.
class ClassicHeroAdjustmentBadge extends StatelessWidget {
  /// Creates a classic hero adjustment chip.
  const ClassicHeroAdjustmentBadge({
    required this.icon,
    required this.color,
    required this.value,
    required this.numberFormat,
    super.key,
  });

  /// Leading icon shown inside the chip.
  final IconData icon;

  /// Accent color used for the chip border and text.
  final Color color;

  /// Signed calorie value displayed in the chip.
  final int value;

  /// Number formatter used for the displayed value.
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final sign = value > 0 ? '+' : '';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs / 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              '$sign${numberFormat.format(value)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
