import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/meal_type_l10n.dart';
import 'package:yamt/features/diary/provider/diary_entries_provider.dart';
import 'package:yamt/features/diary/provider/diary_meal_sections_provider.dart';
import 'package:yamt/features/diary/provider/diary_nutrition_bars_provider.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/inventory_manual_add_page.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_hero_image.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_list/inventory_item_row/inventory_item_eat_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_action_dialogs.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Diary quick-eat sources.
enum DiaryQuickEatSource {
  /// Eat from inventory.
  inventory,

  /// Scan barcode and eat.
  barcode,

  /// Manual product search and eat.
  manualSearch,

  /// AI food estimate and eat.
  ai,
}

/// Compact add menu for a diary meal category.
class DiaryMealQuickAddMenu extends StatelessWidget {
  /// Creates quick add menu.
  const DiaryMealQuickAddMenu({
    required this.mealType,
    required this.onSelected,
    super.key,
  });

  /// Meal type for tooltip/key.
  final MealType mealType;

  /// Source selected by user.
  final ValueChanged<DiaryQuickEatSource> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return PopupMenuButton<DiaryQuickEatSource>(
      key: Key('diary_quick_add_button_${mealType.jsonValue}'),
      tooltip: l10n.diaryQuickEatAddTooltip(mealType.localizedName(l10n)),
      icon: Icon(Icons.add_rounded, color: colors.primary),
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (context) {
        return [
          _item(
            value: DiaryQuickEatSource.inventory,
            icon: Icons.kitchen_outlined,
            label: l10n.diaryQuickEatSourceInventory,
          ),
          _item(
            value: DiaryQuickEatSource.barcode,
            icon: Icons.qr_code_scanner_rounded,
            label: l10n.diaryQuickEatSourceBarcode,
          ),
          _item(
            value: DiaryQuickEatSource.manualSearch,
            icon: Icons.search_rounded,
            label: l10n.diaryQuickEatSourceManualSearch,
          ),
          _item(
            value: DiaryQuickEatSource.ai,
            icon: Icons.auto_awesome_rounded,
            label: l10n.diaryQuickEatSourceAi,
          ),
        ];
      },
    );
  }

  PopupMenuItem<DiaryQuickEatSource> _item({
    required DiaryQuickEatSource value,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem<DiaryQuickEatSource>(
      key: Key('diary_quick_add_source_${value.name}'),
      value: value,
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: AppSpacing.md),
          Text(label),
        ],
      ),
    );
  }
}

/// Runs diary quick-eat flows.
@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  inventoryBackedCalorieEntrySaveFlow,
])
class DiaryQuickEatFlow {
  const DiaryQuickEatFlow._();

  /// Open selected quick-eat source.
  static Future<void> openSource({
    required BuildContext context,
    required WidgetRef ref,
    required DiaryQuickEatSource source,
    required MealType mealType,
    required DateTime selectedDay,
  }) async {
    final loggedAt = _resolveLoggedAt(selectedDay);
    switch (source) {
      case DiaryQuickEatSource.inventory:
        await _openInventoryPicker(
          context: context,
          ref: ref,
          mealType: mealType,
          loggedAt: loggedAt,
        );
      case DiaryQuickEatSource.barcode:
        await _openManualAdd(
          context: context,
          action: InventoryManualAddInitialAction.barcodeScan,
          mealType: mealType,
          loggedAt: loggedAt,
        );
      case DiaryQuickEatSource.manualSearch:
        await _openManualAdd(
          context: context,
          action: InventoryManualAddInitialAction.manualSearch,
          mealType: mealType,
          loggedAt: loggedAt,
        );
      case DiaryQuickEatSource.ai:
        await _openManualAdd(
          context: context,
          action: InventoryManualAddInitialAction.aiSuggestion,
          mealType: mealType,
          loggedAt: loggedAt,
        );
    }
    if (context.mounted) {
      _refreshDiary(ref, loggedAt);
    }
  }

  static Future<void> _openManualAdd({
    required BuildContext context,
    required InventoryManualAddInitialAction action,
    required MealType mealType,
    required DateTime loggedAt,
  }) async {
    await context.push<void>(
      AppRoutes.homeInventoryManualAdd,
      extra: InventoryManualAddRouteArgs(
        initialAction: action,
        quickEatOnly: true,
        preselectedMealType: mealType,
        preselectedLoggedAt: loggedAt,
      ),
    );
  }

  static Future<void> _openInventoryPicker({
    required BuildContext context,
    required WidgetRef ref,
    required MealType mealType,
    required DateTime loggedAt,
  }) async {
    final items =
        ref.read(inventoryItemsControllerProvider).value ??
        const <InventoryItem>[];
    final meals =
        ref.read(preparedMealsControllerProvider).value ??
        const <PreparedMeal>[];
    final selection = await showModalBottomSheet<DiaryInventoryFoodSelection>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DiaryInventoryFoodPicker(
          items: items.where(_canEatItem).toList(growable: false),
          meals: meals
              .where((meal) => !meal.isDepleted)
              .toList(
                growable: false,
              ),
        );
      },
    );
    if (!context.mounted || selection == null) {
      return;
    }
    switch (selection) {
      case DiaryInventoryItemFoodSelection(:final item):
        await _eatInventoryItem(
          context: context,
          ref: ref,
          item: item,
          mealType: mealType,
          loggedAt: loggedAt,
        );
      case DiaryPreparedMealFoodSelection(:final meal):
        await _eatPreparedMeal(
          context: context,
          ref: ref,
          meal: meal,
          mealType: mealType,
          loggedAt: loggedAt,
        );
    }
  }

  static Future<void> _eatInventoryItem({
    required BuildContext context,
    required WidgetRef ref,
    required InventoryItem item,
    required MealType mealType,
    required DateTime loggedAt,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final maxAmount = _maxInventoryAmount(item);
    if (maxAmount == null) {
      return;
    }
    final request = await showInventoryItemEatSheet(
      context: context,
      item: item,
      maxAmount: maxAmount,
      invalidAmountMessage: l10n.inventoryReceiptReviewInvalidNumber,
      initialLoggedAt: loggedAt,
      initialMealType: mealType,
    );
    if (!context.mounted || request == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final pendingConsumption = await controller.stagePendingConsumption(
      item.id,
      request.inventoryAmount,
    );
    if (pendingConsumption == null) {
      _showSnackBarWithMessenger(messenger, l10n.inventoryItemActionFailed);
      return;
    }
    if (!context.mounted) {
      await controller.discardPendingConsumption(pendingConsumption.id);
      return;
    }
    final flowContext = context;
    await InventoryItemEatFlow.complete(
      context: flowContext,
      ref: ref,
      itemBeforeMutation: item,
      request: request,
      pendingConsumptionId: pendingConsumption.id,
    );
  }

  static Future<void> _eatPreparedMeal({
    required BuildContext context,
    required WidgetRef ref,
    required PreparedMeal meal,
    required MealType mealType,
    required DateTime loggedAt,
  }) async {
    final result = await showPreparedMealEatDialog(
      context,
      meal,
      useRootNavigator: true,
      initialLoggedAt: loggedAt,
      initialMealType: mealType,
    );
    if (!context.mounted || result == null) {
      return;
    }
    final saved = await ref
        .read(preparedMealsControllerProvider.notifier)
        .consumePreparedMeal(
          mealId: meal.id,
          consumedPortions: result.portions,
          mealType: result.mealType,
          loggedDay: result.loggedDay,
        );
    if (!context.mounted || saved) {
      return;
    }
    _showSnackBar(
      context,
      AppLocalizations.of(context)!.preparedMealActionFailed,
    );
  }

  static bool _canEatItem(InventoryItem item) {
    return _maxInventoryAmount(item) != null;
  }

  static int? _maxInventoryAmount(InventoryItem item) {
    if (item.usesAmountProgress) {
      if (item.amountUnit == null || item.currentAmount < 1) {
        return null;
      }
      return item.currentAmount;
    }
    if (item.quantity < 1) {
      return null;
    }
    return item.quantity;
  }

  static DateTime _resolveLoggedAt(DateTime selectedDay) {
    final now = DateTime.now();
    final normalizedDay = normalizeDiaryDay(selectedDay);
    final today = normalizeDiaryDay(now);
    final day = normalizedDay.isAfter(today) ? today : normalizedDay;
    return DateTime(day.year, day.month, day.day, now.hour, now.minute);
  }

  static void _refreshDiary(WidgetRef ref, DateTime loggedAt) {
    final day = normalizeDiaryDay(loggedAt);
    ref
      ..invalidate(diaryEntriesForDayProvider(day))
      ..invalidate(diaryMealSectionsProvider(day))
      ..invalidate(diaryNutritionBarsDataProvider(day));
  }

  static void _showSnackBar(BuildContext context, String message) {
    _showSnackBarWithMessenger(ScaffoldMessenger.of(context), message);
  }

  static void _showSnackBarWithMessenger(
    ScaffoldMessengerState messenger,
    String message,
  ) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

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
