import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_amount_utils.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_action_button.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_step_layout.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_storage_container_models.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_tare_utensil_picker.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_weight_input_row.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/'
    'cooking_flow_text_styles.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Preparation step for cookflow.
class CookingFlowPreparationPage extends StatelessWidget {
  /// Creates preparation step.
  const new({
    required this.storageContainers,
    required this.onContainerChanged,
    required this.onContainerTaraUtensilSelected,
    required this.onAddContainerPressed,
    required this.onRemoveContainerPressed,
    required this.onOpenKitchenUtensilsPressed,
    super.key,
  });

  /// Selected storage containers.
  final List<CookingFlowStorageContainerView> storageContainers;

  /// Called when text fields change.
  final ValueChanged<String> onContainerChanged;

  /// Called when user selects a stored utensil for one container.
  final void Function(String containerId, KitchenUtensil utensil)
  onContainerTaraUtensilSelected;

  /// Adds another storage container.
  final VoidCallback onAddContainerPressed;

  /// Removes one storage container.
  final ValueChanged<String> onRemoveContainerPressed;

  /// Called when user opens kitchen utensil library.
  final VoidCallback onOpenKitchenUtensilsPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return CookingFlowStepLayout(
      title: l10n.cookflowPreparationTitle,
      subtitle: l10n.cookflowPreparationBody,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.cookflowStorageContainersTitle,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: colors.ink, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            CookingFlowSecondaryActionButton(
              label: l10n.cookflowAddStorageContainerButton,
              onPressed: onAddContainerPressed,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var index = 0; index < storageContainers.length; index++) ...[
          _PreparationStorageContainerCard(
            container: storageContainers[index],
            index: index,
            onContainerChanged: onContainerChanged,
            onContainerTaraUtensilSelected: onContainerTaraUtensilSelected,
            onRemoveContainerPressed: onRemoveContainerPressed,
            onOpenKitchenUtensilsPressed: onOpenKitchenUtensilsPressed,
          ),
          if (index < storageContainers.length - 1)
            const SizedBox(height: AppSpacing.lg),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.cookflowPreparationHint,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.muted),
        ),
      ],
    );
  }
}

/// One container to fill: its name, the tare and the saved utensils. The box
/// is square with a thin rule, because it shows a thing and is not tapped.
class _PreparationStorageContainerCard extends StatelessWidget {
  const new({
    required this.container,
    required this.index,
    required this.onContainerChanged,
    required this.onContainerTaraUtensilSelected,
    required this.onRemoveContainerPressed,
    required this.onOpenKitchenUtensilsPressed,
  });

  final CookingFlowStorageContainerView container;
  final int index;
  final ValueChanged<String> onContainerChanged;
  final void Function(String containerId, KitchenUtensil utensil)
  onContainerTaraUtensilSelected;
  final ValueChanged<String> onRemoveContainerPressed;
  final VoidCallback onOpenKitchenUtensilsPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final taraWeight = _parseWeight(container.taraController.text).round();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.rule),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _containerTitle(l10n, container, index),
                    style: context.cookingFlowDisplayStyle(
                      textTheme.titleLarge,
                    ),
                  ),
                ),
                if (container.canRemove) ...<Widget>[
                  const SizedBox(width: AppSpacing.md),
                  TextButton.icon(
                    onPressed: () => onRemoveContainerPressed(container.id),
                    style: TextButton.styleFrom(foregroundColor: colors.muted),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(l10n.cookflowRemoveContainerTooltip),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.cookflowContainerTaraLabel.toUpperCase(),
              style: context.cookingFlowKickerStyle,
            ),
            const SizedBox(height: AppSpacing.xs),
            CookingFlowWeightInputRow(
              controller: container.taraController,
              unitLabel: l10n.cookflowGramUnit,
              onChanged: onContainerChanged,
            ),
            const SizedBox(height: AppSpacing.xl),
            CookingFlowTareUtensilPicker(
              selectedTaraWeightGrams: taraWeight,
              selectedUtensilId: container.selectedTaraUtensilId,
              onSelected: (utensil) {
                onContainerTaraUtensilSelected(container.id, utensil);
              },
              onOpenKitchenUtensilsPressed: onOpenKitchenUtensilsPressed,
            ),
          ],
        ),
      ),
    );
  }
}

String _containerTitle(
  AppLocalizations l10n,
  CookingFlowStorageContainerView container,
  int index,
) {
  final label = container.labelController.text.trim();
  if (label.isNotEmpty) {
    return label;
  }
  return l10n.cookflowContainerNameHint(index + 1);
}

double _parseWeight(String value) {
  return parseCookingFlowQuantity(value) ?? 0;
}
