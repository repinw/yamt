import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_scope.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_scope_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Switches between the household list, the private list and both, each
/// with the number of its entries, and says who sees the list shown.
class ShoppingListScopeBar extends ConsumerWidget {
  /// Creates the bar with the number of entries on each list.
  const new({required this.counts, super.key});

  /// The entries on each list.
  final Map<ShoppingListScope, int> counts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scope = ref.watch(shoppingListScopeControllerProvider);
    String label(ShoppingListScope of) => l10n.shoppingListScopeCount(
      shoppingListScopeLabel(l10n, of),
      counts[of] ?? 0,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<ShoppingListScope>(
          key: ShoppingListPageKeys.scopeBar,
          showSelectedIcon: false,
          segments: [
            for (final of in ShoppingListScope.values)
              ButtonSegment(
                value: of,
                icon: of == ShoppingListScope.private
                    ? const Icon(Icons.lock_outline_rounded)
                    : null,
                label: Text(
                  label(of),
                  key: ShoppingListPageKeys.scope(of.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          selected: {scope},
          onSelectionChanged: (selected) => unawaited(
            ref
                .read(shoppingListScopeControllerProvider.notifier)
                .select(selected.single),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          switch (scope) {
            ShoppingListScope.household => l10n.shoppingListScopeHouseholdHint,
            ShoppingListScope.private => l10n.shoppingListScopePrivateHint,
            ShoppingListScope.both => l10n.shoppingListScopeBothHint,
          },
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The name of [scope] on the switch.
String shoppingListScopeLabel(AppLocalizations l10n, ShoppingListScope scope) =>
    switch (scope) {
      ShoppingListScope.household => l10n.shoppingListScopeHousehold,
      ShoppingListScope.private => l10n.shoppingListScopePrivate,
      ShoppingListScope.both => l10n.shoppingListScopeBoth,
    };
