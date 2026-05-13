import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Burn Week label and optional star/heart counters.
class DiaryBalanceGameHeader extends StatelessWidget {
  /// Creates the Burn Week game header.
  const DiaryBalanceGameHeader({
    required this.label,
    required this.starCount,
    required this.heartCount,
    required this.onHeartTap,
    super.key,
  });

  /// Header label.
  final String label;

  /// Optional star count.
  final int? starCount;

  /// Optional heart count.
  final int? heartCount;

  /// Called when the heart badge is tapped.
  final VoidCallback? onHeartTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final starCount = this.starCount;
    final heartCount = this.heartCount;
    final showCounters = starCount != null && heartCount != null;

    return SizedBox(
      height: diaryBalanceGameHeaderHeight,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (showCounters) ...[
            const SizedBox(width: AppSpacing.sm),
            _BurnWeekCounterBadge(
              icon: Icons.stars_rounded,
              iconColor: const Color(0xFFF59E0B),
              label: l10n.diaryCounterLabel(starCount),
            ),
            const SizedBox(width: AppSpacing.xs),
            _BurnWeekCounterBadge(
              icon: Icons.favorite_rounded,
              iconColor: colors.error,
              label: l10n.diaryCounterLabel(heartCount),
              onTap: onHeartTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _BurnWeekCounterBadge extends StatelessWidget {
  const _BurnWeekCounterBadge({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final child = SizedBox(
      height: diaryBalanceCounterBadgeHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: diaryBalanceCounterIconSize),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(999),
      child: AppInkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: child,
      ),
    );
  }
}
