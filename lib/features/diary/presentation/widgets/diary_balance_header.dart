part of 'diary_balance_card.dart';

class _DiaryBalanceGameHeader extends StatelessWidget {
  const _DiaryBalanceGameHeader({
    required this.label,
    required this.starCount,
    required this.heartCount,
    required this.onHeartTap,
  });

  final String label;
  final int? starCount;
  final int? heartCount;
  final VoidCallback? onHeartTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final starCount = this.starCount;
    final heartCount = this.heartCount;
    final showCounters = starCount != null && heartCount != null;

    return SizedBox(
      height: _balanceGameHeaderHeight,
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
      height: _balanceCounterBadgeHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: _balanceCounterIconSize),
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
      child: InkWell(
        enableFeedback: false,
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: child,
      ),
    );
  }
}
