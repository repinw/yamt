import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cooking_flow/application/cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_action_button/cooking_flow_secondary_action_button.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_inventory_assignment_sheet/cooking_flow_inventory_assignment_preview.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Suggests a Vorrat item that arrived during the shopping detour.
class CookingFlowInventoryReturnSuggestionPanel extends StatelessWidget {
  /// Creates the panel.
  const new({required this.item, required this.onPressed, super.key});

  /// Suggested Vorrat item.
  final InventoryItem item;

  /// Assigns the suggested item.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final amountLabel = cookingFlowInventoryAmountLabel(item);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.tile,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CookingFlowInventoryAssignmentPreview(
                label: item.name,
                imageUrl: item.imageUrl,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.cookflowInventoryReturnSuggestion,
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${item.name} · $amountLabel',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: CookingFlowSecondaryActionButton(
              label: l10n.cookflowInventoryReturnSuggestionButton,
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}
