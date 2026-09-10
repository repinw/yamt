import 'package:flutter/material.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Empty-list illustration and localized explanation.
class ShoppingListEmptyState extends StatelessWidget {
  /// Creates the empty-list message.
  const ShoppingListEmptyState({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Icon(
          Icons.shopping_bag_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context)!.shoppingListEmptyState,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
