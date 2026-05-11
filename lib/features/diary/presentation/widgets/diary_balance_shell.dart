part of 'diary_balance_card.dart';

class _DiaryBalanceShell extends StatelessWidget {
  const _DiaryBalanceShell({required this.child, this.framed = true});

  final Widget child;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!framed) {
      return child;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFEEF2EF),
        borderRadius: BorderRadius.circular(_balanceCardRadius),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFDDE6E0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.1),
            blurRadius: isDark ? 26 : 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: child,
      ),
    );
  }
}

class _DiaryBalanceLoading extends StatelessWidget {
  const _DiaryBalanceLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFF1F2937)
        : const Color(0xFFDDE6E0);
    final highlightColor = isDark
        ? const Color(0xFF374151)
        : const Color(0xFFF8FAFC);

    return _DiaryBalanceShell(
      child: _DiaryBalanceSkeleton(
        baseColor: baseColor,
        highlightColor: highlightColor,
      ),
    );
  }
}

class _DiaryBalanceScheduledRestartCard extends StatelessWidget {
  const _DiaryBalanceScheduledRestartCard({
    required this.scheduledRestartDate,
  });

  final DateTime scheduledRestartDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final colors = Theme.of(context).colorScheme;

    return _DiaryBalanceShell(
      child: Column(
        children: [
          Icon(
            Icons.favorite_border_rounded,
            color: colors.error,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.burnWeekRunOverTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.error,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.burnWeekRunRestartsOn(
              dateFormat.format(scheduledRestartDate),
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryBalanceScaleLabel extends StatelessWidget {
  const _DiaryBalanceScaleLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _DiaryBalanceBufferBadge extends StatelessWidget {
  const _DiaryBalanceBufferBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 16,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiaryBalanceStatTileStyle {
  const _DiaryBalanceStatTileStyle({
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

  factory _DiaryBalanceStatTileStyle.eaten({
    required bool isDark,
    required Color valueColor,
    required Color subtitleColor,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return _DiaryBalanceStatTileStyle(
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

  factory _DiaryBalanceStatTileStyle.left({required Gradient gradient}) {
    return _DiaryBalanceStatTileStyle(
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

  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color labelColor;
  final Color valueColor;
  final Color subtitleColor;
  final Color backgroundColor;
  final Color borderColor;
  final Gradient? gradient;
  final Color? shadowColor;
}

class _DiaryBalanceStatTile extends StatelessWidget {
  const _DiaryBalanceStatTile({
    required this.label,
    required this.value,
    required this.style,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;
  final _DiaryBalanceStatTileStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _balanceStatTileHeight,
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

class _DiaryBalanceSkeleton extends StatefulWidget {
  const _DiaryBalanceSkeleton({
    required this.baseColor,
    required this.highlightColor,
  });

  final Color baseColor;
  final Color highlightColor;

  @override
  State<_DiaryBalanceSkeleton> createState() => _DiaryBalanceSkeletonState();
}

class _DiaryBalanceSkeletonState extends State<_DiaryBalanceSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shaderOffset = boundsWidthMultiplier(_controller.value);

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.28, 0.5, 0.72],
            ).createShader(
              Rect.fromLTWH(
                bounds.left + (bounds.width * shaderOffset),
                bounds.top,
                bounds.width,
                bounds.height,
              ),
            );
          },
          child: child,
        );
      },
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _balanceProgressAreaHeight,
            child: Align(
              child: _SkeletonBlock(height: _balanceProgressHeight),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SkeletonBlock(width: 52, height: 14),
              _SkeletonBlock(width: 86, height: 14),
            ],
          ),
          SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(child: _SkeletonBlock(height: _balanceStatTileHeight)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: _SkeletonBlock(height: _balanceStatTileHeight)),
            ],
          ),
        ],
      ),
    );
  }

  double boundsWidthMultiplier(double animationValue) {
    return -1 + (animationValue * 2);
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height, this.width});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
