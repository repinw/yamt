// Internal split widgets are public only for sibling imports.
// ignore_for_file: public_member_api_docs, use_key_in_widget_constructors

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The three choices of an ingredient row as chips with a word each:
/// take it from the Vorrat, put it on the shopping list, or leave it out.
class CookingFlowInventoryRowActions extends StatelessWidget {
  const new({
    required this.selectedAction,
    required this.onAssignPressed,
    required this.onShoppingPressed,
    required this.onIgnorePressed,
  });

  final CookingFlowInventoryRowAction? selectedAction;
  final VoidCallback onAssignPressed;
  final VoidCallback onShoppingPressed;
  final VoidCallback onIgnorePressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        CookingFlowInventoryActionButton(
          icon: Icons.inventory_2_outlined,
          tooltip: l10n.cookflowAssignTooltip,
          isActive: selectedAction == CookingFlowInventoryRowAction.assigned,
          onPressed: onAssignPressed,
        ),
        CookingFlowInventoryActionButton(
          icon: Icons.shopping_cart_outlined,
          tooltip: l10n.cookflowShoppingCartTooltip,
          isActive:
              selectedAction == CookingFlowInventoryRowAction.shoppingCart,
          onPressed: onShoppingPressed,
        ),
        CookingFlowInventoryActionButton(
          icon: Icons.not_interested_rounded,
          tooltip: l10n.cookflowIgnoreTooltip,
          isActive: selectedAction == CookingFlowInventoryRowAction.ignored,
          onPressed: onIgnorePressed,
        ),
      ],
    );
  }
}

/// One choice chip: a small icon and its word. The selected chip is filled
/// with ink; lime stays reserved for the screen's main button.
class CookingFlowInventoryActionButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onPressed,
  });

  final IconData icon;

  /// Word shown on the chip; also the tooltip, so tests can find it.
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final foreground = isActive ? colors.paper : colors.ink;

    return Tooltip(
      message: tooltip,
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: foreground,
          backgroundColor: isActive ? colors.ink : colors.tile,
          minimumSize: const Size(AppGraphit.chipHeight, AppGraphit.chipHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: const StadiumBorder(),
        ),
        icon: Icon(icon, size: AppGraphit.chipIcon),
        label: Text(
          tooltip,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
