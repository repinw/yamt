import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_trip_summary.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows what finishing the trip does, as [trip] sums it up: the entries in
/// the cart leave the list, open ones stay, saved ones stay saved. Returns
/// true when
/// the user finished, null when they closed the page. The receipt comes
/// later, in the Vorrat: after the shop the app is closed.
Future<bool?> showShoppingListFinishPage(
  BuildContext context, {
  required ShoppingTripSummary trip,
}) => Navigator.of(context).push(
  MaterialPageRoute<bool>(
    fullscreenDialog: true,
    builder: (_) => ShoppingListFinishPage(trip: trip),
  ),
);

/// The end of a trip: what is in the cart and what stays open. Pops with
/// true when the user finishes.
class ShoppingListFinishPage extends StatelessWidget {
  /// Creates the page for [trip].
  const new({required this.trip, super.key});

  /// What finishing does with the entries of the list.
  final ShoppingTripSummary trip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ShoppingTripSummary(:cart, :openCount, :savedNames) = trip;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: ShoppingListPageKeys.finishCancelButton,
          tooltip: l10n.shoppingFinishCloseAction,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(l10n.shoppingFinishTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.md,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        children: [
          Text(
            l10n.shoppingFinishDoneCount(cart.length),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.shoppingFinishHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _CartCard(items: cart),
          if (openCount > 0)
            _NoteCard(
              icon: Icons.format_list_bulleted_rounded,
              text: l10n.shoppingFinishOpenLeft(openCount),
            ),
          if (savedNames.isNotEmpty)
            _NoteCard(
              icon: Icons.star_rounded,
              text: l10n.shoppingFinishSavedStay(
                savedNames.length,
                _nameList(l10n, savedNames),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xs,
            AppSpacing.xxl,
            AppSpacing.xl,
          ),
          child: FilledButton(
            key: ShoppingListPageKeys.finishConfirmButton,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.shoppingFinishTitle),
          ),
        ),
      ),
    );
  }
}

class _CartCard extends StatelessWidget {
  const new({required this.items});

  final List<ShoppingListItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Card.filled(
      color: colors.surfaceContainerLowest,
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (index, item) in items.indexed) ...[
            if (index > 0) const Divider(height: 1, indent: AppSpacing.xxxxl),
            ListTile(
              leading: Icon(Icons.check_rounded, color: colors.primary),
              title: Text(item.name),
              trailing: Text(l10n.shoppingAddQuantity(item.quantity)),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const new({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.filled(
      color: theme.colorScheme.surfaceContainerLowest,
      margin: const EdgeInsets.only(top: AppSpacing.md),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// [names] as a list in the user's language: "Milch, Brot und Eier".
String _nameList(AppLocalizations l10n, List<String> names) => names.length < 2
    ? names.join()
    : l10n.shoppingNameListLast(
        names.sublist(0, names.length - 1).join(l10n.shoppingNameListSeparator),
        names.last,
      );
