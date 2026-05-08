import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_hero_image.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Food selected from the diary inventory quick-eat picker.
sealed class DiaryInventoryFoodSelection {
  /// Creates a diary inventory food selection.
  const DiaryInventoryFoodSelection();
}

/// Inventory item selected from the diary quick-eat picker.
class DiaryInventoryItemFoodSelection extends DiaryInventoryFoodSelection {
  /// Creates an inventory item selection.
  const DiaryInventoryItemFoodSelection(this.item);

  /// Selected inventory item.
  final InventoryItem item;
}

/// Prepared meal selected from the diary quick-eat picker.
class DiaryPreparedMealFoodSelection extends DiaryInventoryFoodSelection {
  /// Creates a prepared meal selection.
  const DiaryPreparedMealFoodSelection(this.meal);

  /// Selected prepared meal.
  final PreparedMeal meal;
}

/// Inventory and prepared-meal picker used by diary quick eat.
class DiaryInventoryFoodPicker extends ConsumerWidget {
  /// Creates inventory and prepared-meal picker.
  const DiaryInventoryFoodPicker({
    required this.items,
    required this.meals,
    super.key,
  });

  /// Available inventory items.
  final List<InventoryItem> items;

  /// Available prepared meals.
  final List<PreparedMeal> meals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final visibleCount = items.length + meals.length;

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
                      child: visibleCount == 0
                          ? Center(
                              child: Padding(
                                padding: AppInsets.card,
                                child: Text(l10n.diaryQuickEatInventoryEmpty),
                              ),
                            )
                          : ListView.builder(
                              itemCount: visibleCount,
                              itemBuilder: (context, index) {
                                if (index < items.length) {
                                  final item = items[index];
                                  return _InventoryFoodTile(
                                    fallbackIcon: Icons.kitchen_outlined,
                                    imageUrl: item.imageUrl,
                                    title: item.name,
                                    subtitle: item.brand,
                                    onTap: () => Navigator.of(context).pop(
                                      DiaryInventoryItemFoodSelection(item),
                                    ),
                                  );
                                }

                                final meal = meals[index - items.length];
                                return _InventoryFoodTile(
                                  fallbackIcon: Icons.restaurant_menu_rounded,
                                  imageUrl: meal.imageUrl,
                                  imageBytes: _storedMealImageBytes(ref, meal),
                                  title: meal.name,
                                  subtitle: l10n.preparedMealPortionsRemaining(
                                    meal.remainingPortions,
                                    meal.totalPortions,
                                  ),
                                  onTap: () => Navigator.of(context).pop(
                                    DiaryPreparedMealFoodSelection(meal),
                                  ),
                                );
                              },
                            ),
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

  Uint8List? _storedMealImageBytes(WidgetRef ref, PreparedMeal meal) {
    final imageRef = maybeLocalImageAssetRef(meal.imageAssetId);
    if (imageRef == null) {
      return null;
    }
    return ref.watch(localImageBytesProvider(imageRef)).asData?.value;
  }
}

class _InventoryFoodTile extends StatelessWidget {
  const _InventoryFoodTile({
    required this.fallbackIcon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.imageUrl,
    this.imageBytes,
  });

  final IconData fallbackIcon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final String? imageUrl;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _InventoryFoodImage(
        fallbackIcon: fallbackIcon,
        imageUrl: imageUrl,
        imageBytes: imageBytes,
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null || subtitle!.trim().isEmpty
          ? null
          : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _InventoryFoodImage extends StatelessWidget {
  const _InventoryFoodImage({
    required this.fallbackIcon,
    this.imageUrl,
    this.imageBytes,
  });

  static const double _size = 44;

  final IconData fallbackIcon;
  final String? imageUrl;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
      color: colors.secondaryContainer.withValues(alpha: 0.75),
      child: Center(
        child: Icon(
          fallbackIcon,
          size: 22,
          color: colors.onSecondaryContainer,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox.square(
        dimension: _size,
        child: InventoryEatFlowHeroImage(
          imageUrl: imageUrl,
          imageBytes: imageBytes,
          fallback: fallback,
        ),
      ),
    );
  }
}
