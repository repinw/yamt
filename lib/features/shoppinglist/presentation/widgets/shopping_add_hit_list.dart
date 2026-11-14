import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_planned_meal.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_quick_entry.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf_placement.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_suggestion_views.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shelf/shopping_item_disc.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shelf/shopping_shelf_labels.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_add_hit_tile.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What the add sheet offers for the typed [entry]: the typed text as a new
/// entry, the known products that match, and more from the shelf of the
/// first of them. With nothing typed it offers the favorites.
class ShoppingAddHitList extends ConsumerWidget {
  /// Creates the list.
  const new({
    required this.entry,
    required this.suggestions,
    required this.onAdd,
    super.key,
  });

  /// What the user typed, split into quantity and text.
  final ShoppingQuickEntry entry;

  /// Products the Vorrat and the receipts suggest.
  final List<ShoppingSuggestion> suggestions;

  /// Puts the product with the name and brand on the list, for the planned
  /// meal a suggestion names.
  final void Function(
    String name,
    String? brand, {
    ShoppingPlannedMeal? plannedFor,
  })
  onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final offer = ref.watch(
      shoppingAddOfferForProvider(
        text: entry.text,
        languageCode: Localizations.localeOf(context).languageCode,
        suggestions: ShoppingSuggestionList(suggestions),
      ),
    );
    if (entry.text.isEmpty) {
      return ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          if (offer.hits.isNotEmpty)
            _ChipRow(
              title: l10n.shoppingAddFavoritesTitle,
              chips: [
                for (final (:hit, :placement) in offer.hits)
                  _chip(
                    context,
                    key: ShoppingListPageKeys.addSheetFavorite(hit.key),
                    name: hit.name,
                    placement: placement,
                    onTap: () =>
                        onAdd(hit.name, hit.brand, plannedFor: hit.plannedFor),
                  ),
              ],
            ),
        ],
      );
    }
    final typed = offer.typed;
    final newEntry = ListTile(
      key: ShoppingListPageKeys.addSheetNewEntry,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      leading: ShoppingItemDisc(icon: typed.icon, size: AppShopping.itemDisc),
      title: Text(l10n.shoppingAddNewEntry(entry.text)),
      subtitle: Text(
        typed.isAssigned
            ? shoppingShelfLabel(l10n, typed.shelf)
            : l10n.shoppingAddNewEntryUnknown,
      ),
      trailing: entry.quantity > 1
          ? Text(l10n.shoppingAddQuantity(entry.quantity))
          : const Icon(Icons.add_rounded),
      onTap: () => onAdd(entry.text, null),
    );
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        if (offer.isTypedFirst) newEntry,
        for (final (:hit, :placement) in offer.hits)
          ShoppingAddHitTile(
            key: ShoppingListPageKeys.addSheetHit(hit.key),
            hit: hit,
            placement: placement,
            quantity: entry.quantity,
            onTap: () => onAdd(hit.name, hit.brand, plannedFor: hit.plannedFor),
          ),
        if (!offer.isTypedFirst) newEntry,
        if (offer.ideas.isNotEmpty)
          _ChipRow(
            title: l10n.shoppingAddMoreFromShelf(
              shoppingShelfLabel(l10n, offer.ideaShelf),
            ),
            chips: [
              for (final idea in offer.ideas)
                _chip(
                  context,
                  key: ShoppingListPageKeys.addSheetShelfIdea(idea.name),
                  name: idea.name,
                  placement: (
                    shelf: idea.shelf,
                    icon: idea.icon,
                    isAssigned: true,
                  ),
                  onTap: () => onAdd(idea.name, null),
                ),
            ],
          ),
      ],
    );
  }

  Widget _chip(
    BuildContext context, {
    required Key key,
    required String name,
    required ShoppingShelfPlacement placement,
    required VoidCallback onTap,
  }) => ActionChip(
    key: key,
    avatar: Icon(shoppingItemIconData(placement.icon)),
    label: Text(name),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    onPressed: onTap,
  );
}

class _ChipRow extends StatelessWidget {
  const new({required this.title, required this.chips});

  final String title;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: chips,
          ),
        ],
      ),
    );
  }
}
