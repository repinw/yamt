import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// How many entries are in the cart, as a line and a bar, and how a tile is
/// used.
class ShoppingListProgressHeader extends StatelessWidget {
  /// Creates the header.
  const new({required this.doneCount, required this.entryCount, super.key});

  /// Entries in the cart.
  final int doneCount;

  /// Entries on the list; more than zero.
  final int entryCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.shoppingListProgress(doneCount, entryCount),
          key: ShoppingListPageKeys.progressLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ExcludeSemantics(
          child: LinearProgressIndicator(
            value: doneCount / entryCount,
            minHeight: AppShopping.progressBarHeight,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.shoppingListTileHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
