// Internal split file. Public names are imported only by sibling widgets.
// ignore_for_file: public_member_api_docs, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:yamt/features/inventory/presentation/constants/'
    'inventory_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_hero.dart';

class InventoryItemEatHero extends StatelessWidget {
  const InventoryItemEatHero({
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
      fallback: InventoryItemEatHeroFallback(
        colors: Theme.of(context).colorScheme,
      ),
    );
  }
}

class InventoryItemEatHeroFallback extends StatelessWidget {
  const InventoryItemEatHeroFallback({required this.colors});

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
