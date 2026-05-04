part of 'diary_balance_card.dart';

class _DiaryBalanceShell extends StatelessWidget {
  const _DiaryBalanceShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      Localizations.localeOf(context).toString(),
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

class _DiaryBalanceStatTile extends StatelessWidget {
  const _DiaryBalanceStatTile({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.backgroundColor,
    required this.borderColor,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color valueColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _balanceStatTileHeight,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: valueColor,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
          ),
          if (subtitle case final subtitle?) ...[
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                subtitle,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
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
