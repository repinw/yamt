import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One suggestion in the strip: a tap puts it on the list, the cross pushes
/// it behind the others.
class ShoppingSuggestionCard extends StatelessWidget {
  /// Creates the card.
  const new({
    required this.suggestion,
    required this.onAdd,
    required this.onPushBack,
    super.key,
  });

  /// The suggested product.
  final ShoppingSuggestion suggestion;

  /// Puts the product on the list; null while that is being saved.
  final VoidCallback? onAdd;

  /// Pushes the suggestion behind the others.
  final VoidCallback onPushBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final disc = AppShopping.letterDisc * scale;
    final room = MediaQuery.sizeOf(context).width - 2 * AppSpacing.xxl;
    final width = AppShopping.suggestionCardWidth * scale;
    return SizedBox(
      width: width < room ? width : room,
      child: Material(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Semantics(
                button: true,
                onTapHint: l10n.shoppingListSuggestionAddHint,
                child: AppInkWell(
                  onTap: onAdd,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Row(
                      children: [
                        Container(
                          width: disc,
                          height: disc,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.inverseSurface,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: disc * AppShopping.letterDiscTickRatio,
                            color: colors.onInverseSurface,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                suggestion.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _reason(l10n),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.shoppingListSuggestionPushBackAction(
                suggestion.name,
              ),
              onPressed: onPushBack,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }

  String _reason(AppLocalizations l10n) {
    final reason = suggestion.isOutOfStock
        ? l10n.shoppingListOutOfStock
        : suggestion.isLowStock
        ? l10n.shoppingListLowStock
        : l10n.shoppingListPurchaseCount(suggestion.purchaseCount);
    final brand = suggestion.brand?.trim() ?? '';
    return brand.isEmpty
        ? reason
        : l10n.shoppingListSuggestionBrandReason(brand, reason);
  }
}
