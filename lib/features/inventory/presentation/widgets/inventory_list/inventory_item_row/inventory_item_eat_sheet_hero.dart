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

  static const _thumbSize = 64.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalizedImageUrl = normalizeProductImageUrl(imageUrl);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: SizedBox.square(
              dimension: _thumbSize,
              child: normalizedImageUrl == null
                  ? _InventoryItemEatHeroFallback(colors: colors)
                  : AppCachedNetworkImage(
                      imageUrl: normalizedImageUrl,
                      fit: BoxFit.cover,
                      cacheWidth:
                          (_thumbSize *
                                  MediaQuery.devicePixelRatioOf(
                                    context,
                                  ))
                              .round(),
                      cacheHeight:
                          (_thumbSize *
                                  MediaQuery.devicePixelRatioOf(
                                    context,
                                  ))
                              .round(),
                      filterQuality: FilterQuality.low,
                      gaplessPlayback: true,
                      errorBuilder: (_, error, stackTrace) {
                        return _InventoryItemEatHeroFallback(colors: colors);
                      },
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
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
          ),
          const SizedBox(width: AppSpacing.md),
          IconButton.filledTonal(
            key: const Key('inventory_item_amount_dialog_cancel_button'),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _InventoryItemEatHeroFallback extends StatelessWidget {
  const _InventoryItemEatHeroFallback({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colors.surfaceContainerHigh,
      child: Center(
        child: Text(
          AppInventoryItemVisuals.fallbackEmoji,
          key: const Key('inventory_item_eat_sheet_hero_fallback'),
          style: Theme.of(context).textTheme.displaySmall,
        ),
      ),
    );
  }
}
