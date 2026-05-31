import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_result_quality.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_product_candidate_widgets.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Search result list for manual product search.
class ManualProductSearchResults extends StatelessWidget {
  /// Creates search results.
  const ManualProductSearchResults({
    required this.results,
    required this.onSelect,
    super.key,
    this.onStoreSelect,
    this.onEatSelect,
  });

  /// Search results.
  final List<OffProductSearchResult> results;

  /// Called when a result is selected.
  final ValueChanged<OffProductSearchResult> onSelect;

  /// Called when a result should be stored.
  final ValueChanged<OffProductSearchResult>? onStoreSelect;

  /// Called when a result should be eaten now.
  final ValueChanged<OffProductSearchResult>? onEatSelect;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        for (var index = 0; index < results.length; index++) ...[
          Builder(
            builder: (context) {
              final result = results[index];
              return InventoryProductCandidateTile(
                key: Key('receipt_review_manual_search_result_${result.code}'),
                name: result.name,
                brand: result.brand,
                imageUrl: result.imageUrl,
                packageWeight: result.packageWeight,
                nutrition: result.nutrition,
                statusLabel: _nutritionGradeLabel(
                  l10n,
                  gradeOffProductNutrition(result.nutrition),
                ),
                onTap: () => onSelect(result),
                trailing: onEatSelect != null
                    ? _ManualProductSearchActions(
                        result: result,
                        onStore: onStoreSelect,
                        onEat: onEatSelect!,
                      )
                    : null,
              );
            },
          ),
          if (index != results.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

String _nutritionGradeLabel(
  AppLocalizations l10n,
  OffProductNutritionGrade grade,
) {
  return switch (grade) {
    OffProductNutritionGrade.missing => l10n.inventoryManualAddNutritionMissing,
    OffProductNutritionGrade.missingCalories =>
      l10n.inventoryManualAddNutritionMissingCalories,
    OffProductNutritionGrade.incomplete =>
      l10n.inventoryManualAddNutritionIncomplete,
    OffProductNutritionGrade.complete =>
      l10n.inventoryManualAddNutritionComplete,
    OffProductNutritionGrade.verified =>
      l10n.inventoryManualAddNutritionVerified,
  };
}

class _ManualProductSearchActions extends StatelessWidget {
  const _ManualProductSearchActions({
    required this.result,
    required this.onEat,
    this.onStore,
  });

  final OffProductSearchResult result;
  final ValueChanged<OffProductSearchResult> onEat;
  final ValueChanged<OffProductSearchResult>? onStore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return InventoryProductCandidateActions(
      inventoryLabel: l10n.inventoryManualAddResultActionInventory,
      eatLabel: l10n.inventoryManualAddResultActionEat,
      inventoryButtonKey: Key(
        'receipt_review_manual_search_result_store_button_${result.code}',
      ),
      eatButtonKey: Key(
        'receipt_review_manual_search_result_eat_button_${result.code}',
      ),
      showInventoryAction: onStore != null,
      onInventory: () => onStore?.call(result),
      onEat: () => onEat(result),
    );
  }
}
