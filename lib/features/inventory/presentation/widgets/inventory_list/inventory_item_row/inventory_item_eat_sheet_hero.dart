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

  @override
  Widget build(BuildContext context) {
    return InventoryEatFlowHero(
      title: itemName,
      eyebrow: eyebrow,
      imageUrl: imageUrl,
      cancelButtonKey: const Key('inventory_item_amount_dialog_cancel_button'),
      fallback: _InventoryItemEatHeroFallback(
        colors: Theme.of(context).colorScheme,
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
