import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_amount_utils.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_step_layout.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_storage_container_models.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_tare_utensil_picker.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_weight_input_row.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Preparation step for cookflow.
class CookingFlowPreparationPage extends StatelessWidget {
  /// Creates preparation step.
  const CookingFlowPreparationPage({
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
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return CookingFlowStepLayout(
      title: l10n.cookflowPreparationTitle,
      subtitle: l10n.cookflowPreparationBody,
      children: <Widget>[
        DecoratedBox(
          decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
            colors,
            borderRadius: BorderRadius.circular(
              AppInventoryEditorial.cardRadius,
            ),
            blurRadius: 22,
            shadowOffset: const Offset(0, 10),
          ),
          child: Padding(
            padding: AppInsets.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.balance_outlined,
                      color: AppSeedColors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.cookflowStorageContainersTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: l10n.cookflowAddStorageContainerButton,
                      onPressed: onAddContainerPressed,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                for (
                  var index = 0;
                  index < storageContainers.length;
                  index++
                ) ...<Widget>[
                  _PreparationStorageContainerCard(
                    container: storageContainers[index],
                    index: index,
                    onContainerChanged: onContainerChanged,
                    onContainerTaraUtensilSelected:
                        onContainerTaraUtensilSelected,
                    onRemoveContainerPressed: onRemoveContainerPressed,
                    onOpenKitchenUtensilsPressed: onOpenKitchenUtensilsPressed,
                  ),
                  if (index < storageContainers.length - 1)
                    const SizedBox(height: AppSpacing.xxl),
                ],
                const SizedBox(height: AppSpacing.xxl),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FF),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Color(0xFF2450C5),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          l10n.cookflowPreparationHint,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: const Color(0xFF2450C5),
                                height: 1.4,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreparationStorageContainerCard extends StatelessWidget {
  const _PreparationStorageContainerCard({
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
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final taraWeight = _parseWeight(container.taraController.text).round();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (container.canRemove) ...<Widget>[
                  const SizedBox(width: AppSpacing.md),
                  IconButton(
                    tooltip: l10n.cookflowRemoveContainerTooltip,
                    onPressed: () => onRemoveContainerPressed(container.id),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              l10n.cookflowContainerTaraLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CookingFlowWeightInputRow(
              controller: container.taraController,
              unitLabel: l10n.cookflowGramUnit,
              onChanged: onContainerChanged,
            ),
            const SizedBox(height: AppSpacing.xxl),
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
