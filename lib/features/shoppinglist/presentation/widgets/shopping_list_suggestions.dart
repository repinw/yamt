import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/shoppinglist/application/shopping_suggestions.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Recent consumption suggestions, independent of shopping list loading.
@Dependencies([shoppingSuggestions, shoppingSuggestionRetry])
class ShoppingListSuggestions extends ConsumerStatefulWidget {
  /// Creates the suggestions section.
  const ShoppingListSuggestions({super.key});

  @override
  ConsumerState<ShoppingListSuggestions> createState() =>
      _ShoppingListSuggestionsState();
}

class _ShoppingListSuggestionsState
    extends ConsumerState<ShoppingListSuggestions> {
  final _pending = <(String, String?)>{};

  Future<void> _add(ShoppingSuggestion suggestion) async {
    final key = (suggestion.name, suggestion.brand);
    if (!_pending.add(key)) return;
    setState(() {});
    final saved = await ref
        .read(shoppingListControllerProvider.notifier)
        .addItem(name: suggestion.name, brand: suggestion.brand);
    if (!mounted) return;
    setState(() => _pending.remove(key));
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.shoppingListAddFailedError,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final history = ref.watch(shoppingSuggestionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.shoppingListSuggestionsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.shoppingListSuggestionsExplanation,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        history.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => TextButton.icon(
            onPressed: ref.watch(shoppingSuggestionRetryProvider),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.shoppingListSuggestionsRetry),
          ),
          data: (suggestions) {
            if (suggestions.isEmpty) {
              return Text(
                l10n.shoppingListSuggestionsEmpty,
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }
            return Column(
              children: [
                for (final suggestion in suggestions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(suggestion.name),
                    subtitle: Text(
                      [
                        if (suggestion.brand?.isNotEmpty ?? false)
                          suggestion.brand!,
                        if (suggestion.isOutOfStock)
                          l10n.shoppingListOutOfStock
                        else if (suggestion.isLowStock)
                          l10n.shoppingListLowStock,
                        if (suggestion.purchaseCount >= 2)
                          l10n.shoppingListPurchaseCount(
                            suggestion.purchaseCount,
                          ),
                      ].join(' · '),
                    ),
                    trailing: IconButton.outlined(
                      tooltip: l10n.shoppingListAddAction,
                      onPressed:
                          _pending.contains((suggestion.name, suggestion.brand))
                          ? null
                          : () => _add(suggestion),
                      icon: const Icon(Icons.add),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
