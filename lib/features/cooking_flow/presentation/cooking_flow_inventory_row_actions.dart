// Internal split widgets are public only for sibling imports.
// ignore_for_file: public_member_api_docs, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/inventory/presentation/constants/'
    'inventory_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

class CookingFlowInventoryRowActions extends StatelessWidget {
  const CookingFlowInventoryRowActions({
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CookingFlowInventoryActionButton(
          icon: Icons.inventory_2_outlined,
          tooltip: l10n.cookflowAssignTooltip,
          isActive: selectedAction == CookingFlowInventoryRowAction.assigned,
          onPressed: onAssignPressed,
        ),
        const SizedBox(width: AppSpacing.xxs),
        CookingFlowInventoryActionButton(
          icon: Icons.shopping_cart_outlined,
          tooltip: l10n.cookflowShoppingCartTooltip,
          isActive:
              selectedAction == CookingFlowInventoryRowAction.shoppingCart,
          onPressed: onShoppingPressed,
        ),
        const SizedBox(width: AppSpacing.xxs),
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

class CookingFlowInventoryActionButton extends StatelessWidget {
  const CookingFlowInventoryActionButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final successColors = AppInventoryEatActionColors.fromColorScheme(colors);

    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isActive
              ? successColors.iconColor
              : colors.onSurfaceVariant.withValues(alpha: 0.75),
          backgroundColor: isActive
              ? successColors.backgroundColor
              : colors.surfaceContainerLowest,
          side: BorderSide(
            color: isActive
                ? successColors.borderColor
                : colors.outlineVariant.withValues(alpha: 0.16),
          ),
          minimumSize: const Size(28, 28),
          fixedSize: const Size(28, 28),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
