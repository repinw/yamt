import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_state.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_intro_page_hero.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_intro_page_inventory.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_intro_portion_scaler.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Intro step for cookflow.
@Dependencies([InventoryItemsController])
class CookingFlowIntroPage extends ConsumerWidget {
  /// Creates intro step.
  const CookingFlowIntroPage({
    required this.template,
    required this.targetPortions,
    required this.initialDraft,
    required this.shoppingBaselineInventoryItemIds,
    required this.resetSignal,
    required this.onTargetPortionsChanged,
    required this.onRestartPressed,
    required this.onShoppingLabelsResolved,
    required this.onSelectionStateChanged,
    super.key,
  });

  /// Selected recipe template.
  final PreparedMeal template;

  /// Portion count used to scale recipe ingredients before assignment.
  final double targetPortions;

  /// Saved intro draft restored from local session.
  final CookingFlowIntroDraft? initialDraft;

  /// Inventory ids that existed before shopping detour started.
  final List<String> shoppingBaselineInventoryItemIds;

  /// Changes whenever intro UI should reset to empty state.
  final int resetSignal;

  /// Restart callback for clearing saved cookflow session.
  final Future<void> Function() onRestartPressed;

  /// Portion scale callback.
  final ValueChanged<double> onTargetPortionsChanged;

  /// Resolves shopping list labels once an item gets assigned.
  final Future<void> Function(List<String> labels) onShoppingLabelsResolved;

  /// Notifies parent shell about intro CTA state.
  final ValueChanged<CookingFlowIntroSelectionState> onSelectionStateChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final imageRef = maybeLocalImageAssetRef(template.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;
    final inventoryItems =
        ref.watch(inventoryItemsControllerProvider).asData?.value ??
        const <InventoryItem>[];
    final localeCode = Localizations.localeOf(context).languageCode;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: responsivePagePadding(
            context,
            top: AppSpacing.xl,
            bottom: homeShellPageBottomPadding(context),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: AppSpacing.xxxxl),
                    CookingFlowIntroMealHero(
                      label: template.name,
                      imageBytes: storedImageBytes,
                      imageUrl: template.imageUrl,
                    ),
                    const SizedBox(height: AppSpacing.xxxxl),
                    Text(
                      l10n.cookflowIntroHeadline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                        children: <InlineSpan>[
                          TextSpan(text: l10n.cookflowRecipeLabel),
                          TextSpan(
                            text: template.name,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxxxl),
                    CookingFlowIntroPortionScaler(
                      originalPortions: template.totalPortions,
                      targetPortions: targetPortions.round(),
                      onChanged: onTargetPortionsChanged,
                    ),
                    const SizedBox(height: AppSpacing.xxxxl),
                    CookingFlowInventoryCheckCard(
                      template: template,
                      targetPortions: targetPortions.round(),
                      inventoryItems: inventoryItems,
                      localeCode: localeCode,
                      initialDraft: initialDraft,
                      shoppingBaselineInventoryItemIds:
                          shoppingBaselineInventoryItemIds,
                      resetSignal: resetSignal,
                      onRestartPressed: onRestartPressed,
                      onShoppingLabelsResolved: onShoppingLabelsResolved,
                      onSelectionStateChanged: onSelectionStateChanged,
                    ),
                    const SizedBox(height: AppSpacing.xxxxl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
