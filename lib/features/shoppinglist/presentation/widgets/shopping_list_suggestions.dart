import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/shoppinglist/application/shopping_suggestions.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion_queue.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_suggestion_queue_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_suggestion_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The suggestions as a strip to scroll sideways. A tap puts one on the
/// list, the cross pushes it behind the others. Without suggestions the
/// strip takes no room.
class ShoppingListSuggestions extends ConsumerStatefulWidget {
  /// Creates the suggestions strip.
  const new({required this.suggestions, this.onRetry, super.key});

  /// The raw suggestions value to filter and display.
  final AsyncValue<List<ShoppingSuggestion>> suggestions;

  /// Optional retry action triggered when loading suggestions fails.
  final VoidCallback? onRetry;

  @override
  ConsumerState<ShoppingListSuggestions> createState() =>
      _ShoppingListSuggestionsState();
}

class _ShoppingListSuggestionsState
    extends ConsumerState<ShoppingListSuggestions> {
  final _pending = <String>{};

  Future<void> _add(ShoppingSuggestion suggestion) async {
    final key = shoppingSuggestionKey(suggestion);
    if (!_pending.add(key)) return;
    setState(() {});
    final saved = await ref
        .read(shoppingListControllerProvider.notifier)
        .addItem(name: suggestion.name, brand: suggestion.brand);
    if (!mounted) return;
    setState(() => _pending.remove(key));
    if (!saved) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        AppLocalizations.of(context)!.shoppingListAddFailedError,
        tone: AppSnackBarTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(shoppingListControllerProvider).asData?.value ?? [];
    final pushedBack = ref.watch(shoppingSuggestionQueueControllerProvider);
    final queue = widget.suggestions.whenData(
      (suggestions) => visibleShoppingSuggestions(
        suggestions,
        items: items,
        pushedBack: pushedBack,
      ),
    );
    return queue.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: widget.onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.shoppingListSuggestionsRetry),
        ),
      ),
      data: (suggestions) => suggestions.isEmpty
          ? const SizedBox.shrink()
          : _strip(context, suggestions),
    );
  }

  Widget _strip(BuildContext context, List<ShoppingSuggestion> suggestions) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.shoppingListSuggestionsTitle,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            key: ShoppingListPageKeys.suggestionStrip,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, suggestion) in suggestions.indexed) ...[
                    if (index > 0) const SizedBox(width: AppSpacing.xs),
                    ShoppingSuggestionCard(
                      key: ShoppingListPageKeys.suggestion(
                        shoppingSuggestionKey(suggestion),
                      ),
                      suggestion: suggestion,
                      onAdd:
                          _pending.contains(shoppingSuggestionKey(suggestion))
                          ? null
                          : () => _add(suggestion),
                      onPushBack: () => ref
                          .read(
                            shoppingSuggestionQueueControllerProvider.notifier,
                          )
                          .pushBack(suggestion, current: suggestions),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
