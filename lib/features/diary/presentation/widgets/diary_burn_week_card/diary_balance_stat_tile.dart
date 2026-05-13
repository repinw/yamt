import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_constants.dart';

/// Visual styling for a diary balance stat tile.
class DiaryBalanceStatTileStyle {
  /// Creates stat tile styling.
  const DiaryBalanceStatTileStyle({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.labelColor,
    required this.valueColor,
    required this.subtitleColor,
    required this.backgroundColor,
    required this.borderColor,
    this.gradient,
    this.shadowColor,
  });

  /// Styling for eaten kcal.
  factory DiaryBalanceStatTileStyle.eaten({
    required bool isDark,
    required Color valueColor,
    required Color subtitleColor,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return DiaryBalanceStatTileStyle(
      icon: Icons.restaurant_rounded,
      iconColor: valueColor,
      iconBackgroundColor: isDark
          ? const Color(0xFF1E3A5F)
          : const Color(0xFFE8F0FF),
      labelColor: const Color(0xFF94A3B8),
      valueColor: valueColor,
      subtitleColor: subtitleColor,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
    );
  }

  /// Styling for remaining kcal.
  factory DiaryBalanceStatTileStyle.left({required Gradient gradient}) {
    return DiaryBalanceStatTileStyle(
      icon: Icons.local_fire_department_rounded,
      iconColor: Colors.white,
      iconBackgroundColor: Colors.white.withValues(alpha: 0.2),
      labelColor: const Color(0xFFD1FAE5),
      valueColor: Colors.white,
      subtitleColor: const Color(0xFFD1FAE5),
      backgroundColor: const Color(0xFF1FA86A),
      borderColor: Colors.transparent,
      gradient: gradient,
      shadowColor: const Color(0x331FA86A),
    );
  }

  /// Tile icon.
  final IconData icon;

  /// Icon foreground color.
  final Color iconColor;

  /// Icon background color.
  final Color iconBackgroundColor;

  /// Label text color.
  final Color labelColor;

  /// Value text color.
  final Color valueColor;

  /// Subtitle text color.
  final Color subtitleColor;

  /// Tile background color.
  final Color backgroundColor;

  /// Tile border color.
  final Color borderColor;

  /// Optional tile gradient.
  final Gradient? gradient;

  /// Optional tile shadow color.
  final Color? shadowColor;
}

/// Compact stat tile for eaten and remaining kcal.
class DiaryBalanceStatTile extends StatelessWidget {
  /// Creates a stat tile.
  const DiaryBalanceStatTile({
    required this.label,
    required this.value,
    required this.style,
    this.subtitle,
    super.key,
  });

  /// Localized label.
  final String label;

  /// Main value.
  final String value;

  /// Optional subtitle.
  final String? subtitle;

  /// Tile styling.
  final DiaryBalanceStatTileStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: diaryBalanceStatTileHeight,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: style.gradient == null ? style.backgroundColor : null,
        gradient: style.gradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: style.borderColor),
        boxShadow: [
          BoxShadow(
            color: style.shadowColor ?? Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: style.iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.iconColor, size: 13),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: style.labelColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: style.valueColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
          ),
          if (subtitle case final subtitle?) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: style.subtitleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
