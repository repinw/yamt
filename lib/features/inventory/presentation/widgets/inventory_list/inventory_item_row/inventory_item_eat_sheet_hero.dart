part of 'inventory_item_eat_sheet.dart';

class _InventoryItemEatHero extends StatelessWidget {
  const _InventoryItemEatHero({
    required this.itemName,
    required this.eyebrow,
    required this.imageUrl,
  });

  final String itemName;
  final String eyebrow;
  final String? imageUrl;

  static const _heroHeight = 228.0;
  static const _fallbackEmoji = '🍽️';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalizedImageUrl = normalizeProductImageUrl(imageUrl);

    return SizedBox(
      height: _heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppInventoryEditorialSurfaces.backdropGradient(colors),
            ),
          ),
          if (normalizedImageUrl != null)
            LayoutBuilder(
              builder: (context, constraints) {
                final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
                final cacheWidth = (constraints.maxWidth * devicePixelRatio)
                    .ceil();
                final cacheHeight = (_heroHeight * devicePixelRatio).ceil();

                return AppCachedNetworkImage(
                  imageUrl: normalizedImageUrl,
                  fit: BoxFit.cover,
                  cacheWidth: cacheWidth,
                  cacheHeight: cacheHeight,
                  filterQuality: FilterQuality.low,
                  gaplessPlayback: true,
                  errorBuilder: (_, error, stackTrace) {
                    return Center(
                      child: Text(
                        _fallbackEmoji,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    );
                  },
                );
              },
            )
          else
            Center(
              child: Text(
                _fallbackEmoji,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.surface.withValues(alpha: 0.12),
                  colors.surface.withValues(alpha: 0.32),
                  colors.surface.withValues(alpha: 0.92),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.xl,
            right: AppSpacing.xl,
            child: IconButton.filledTonal(
              key: const Key('inventory_item_amount_dialog_cancel_button'),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          Positioned(
            left: AppSpacing.xxl,
            right: AppSpacing.xxl,
            bottom: AppSpacing.xxl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: colors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      eyebrow.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  itemName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
