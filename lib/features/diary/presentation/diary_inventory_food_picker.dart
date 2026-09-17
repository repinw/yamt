import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/features/diary/application/'
    'diary_quick_eat_inventory_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_inventory_food_picker/diary_inventory_food_picker_status.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_inventory_food_picker/diary_inventory_food_tile.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Food selected from the diary inventory quick-eat picker.
sealed class DiaryInventoryFoodSelection {
  /// Creates a diary inventory food selection.
  const new();
}

/// Inventory item selected from the diary quick-eat picker.
class DiaryInventoryItemFoodSelection extends DiaryInventoryFoodSelection {
  /// Creates an inventory item selection.
  const new(this.item);

  /// Selected inventory item.
  final InventoryItem item;
}

/// Prepared meal selected from the diary quick-eat picker.
class DiaryPreparedMealFoodSelection extends DiaryInventoryFoodSelection {
  /// Creates a prepared meal selection.
  const new(this.meal);

  /// Selected prepared meal.
  final PreparedMeal meal;
}

/// Lazily loads inventory and prepared meals inside the quick-eat sheet.
class DiaryInventoryFoodPickerSheet extends ConsumerWidget {
  /// Creates lazy diary inventory picker sheet.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryState = ref.watch(diaryQuickEatInventoryProvider);

    return _DiaryInventoryFoodPickerShell(
      child: inventoryState.when(
        loading: () => const DiaryInventoryFoodPickerLoading(),
        error: (_, _) {
          return DiaryInventoryFoodPickerError(
            onRetry: () => ref.invalidate(diaryQuickEatInventoryProvider),
          );
        },
        data: (inventoryData) {
          return _DiaryInventoryFoodPickerContent(
            items: inventoryData.items,
            meals: inventoryData.meals,
          );
        },
      ),
    );
  }
}

/// Inventory and prepared-meal picker used by diary quick eat.
class DiaryInventoryFoodPicker extends StatelessWidget {
  /// Creates inventory and prepared-meal picker.
  const new({required this.items, required this.meals, super.key});

  /// Available inventory items.
  final List<InventoryItem> items;

  /// Available prepared meals.
  final List<PreparedMeal> meals;

  @override
  Widget build(BuildContext context) {
    return _DiaryInventoryFoodPickerShell(
      child: _DiaryInventoryFoodPickerContent(items: items, meals: meals),
    );
  }
}

class _DiaryInventoryFoodPickerShell extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: AppInsets.pageLarge,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.diaryQuickEatInventoryTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.62,
                      ),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiaryInventoryFoodPickerContent extends ConsumerWidget {
  const new({required this.items, required this.meals});

  final List<InventoryItem> items;
  final List<PreparedMeal> meals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final visibleCount = items.length + meals.length;

    if (visibleCount == 0) {
      return Center(
        child: Padding(
          padding: AppInsets.card,
          child: Text(l10n.diaryQuickEatInventoryEmpty),
        ),
      );
    }

    return ListView.builder(
      itemCount: visibleCount,
      itemBuilder: (context, index) {
        if (index < items.length) {
          final item = items[index];
          return DiaryInventoryFoodTile(
            fallbackIcon: Icons.kitchen_outlined,
            imageUrl: item.imageUrl,
            title: item.name,
            subtitle: item.brand,
            onTap: () =>
                Navigator.of(context)
                    .pop(DiaryInventoryItemFoodSelection(item)),
          );
        }

        final meal = meals[index - items.length];
        return DiaryInventoryFoodTile(
          fallbackIcon: Icons.restaurant_menu_rounded,
          imageUrl: meal.imageUrl,
          imageBytes: _storedMealImageBytes(ref, meal),
          title: meal.name,
          subtitle: l10n.preparedMealPortionsRemaining(
            formatPreparedMealPortions(
              meal.remainingPortions,
              localeName: l10n.localeName,
            ),
            meal.totalPortions,
          ),
          onTap: () =>
              Navigator.of(context).pop(DiaryPreparedMealFoodSelection(meal)),
        );
      },
    );
  }

  static Uint8List? _storedMealImageBytes(WidgetRef ref, PreparedMeal meal) {
    final imageRef = maybeLocalImageAssetRef(meal.imageAssetId);
    if (imageRef == null) {
      return null;
    }
    return ref.watch(localImageBytesProvider(imageRef)).asData?.value;
  }
}
