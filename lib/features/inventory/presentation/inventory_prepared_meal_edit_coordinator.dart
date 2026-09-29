import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meal_templates_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/models/prepared_meal_edit_draft.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _preparedMealImageAssetUuid = Uuid();

/// Saves meal edits and meal templates, with an undo on the Vorrat page.
class InventoryPreparedMealEditCoordinator {
  /// Updates prepared meal details, including persisting changed images.
  Future<bool> updatePreparedMeal({
    required BuildContext context,
    required WidgetRef ref,
    required String mealId,
    required PreparedMealEditResult result,
  }) async {
    final previous = ref
        .read(preparedMealsControllerProvider)
        .asData
        ?.value
        .firstWhereOrNull((meal) => meal.id == mealId);
    final imageAssetId = await _saveImageBytesIfChanged(ref, result);
    final saved = await ref
        .read(preparedMealsControllerProvider.notifier)
        .updatePreparedMealDetails(
          mealId: mealId,
          name: result.name,
          imageChanged: result.imageChanged,
          imageAssetId: imageAssetId,
          totalPortions: result.totalPortions,
          items: result.items,
        );
    if (!saved || !context.mounted) {
      return saved;
    }

    final container = ProviderScope.containerOf(context, listen: false);
    ScaffoldMessenger.of(context).showAppSnackBar(
      AppLocalizations.of(context)!.preparedMealUpdatedMessage,
      onUndo: previous == null
          ? null
          : () => container
                .read(preparedMealsControllerProvider.notifier)
                .updatePreparedMealDetails(
                  mealId: previous.id,
                  name: previous.name,
                  imageChanged: result.imageChanged,
                  imageAssetId: previous.imageAssetId,
                  totalPortions: previous.totalPortions,
                  items: [
                    for (final component in previous.components)
                      PreparedMealItemInput(
                        itemId: component.inventoryItemId,
                        usedAmount: component.usedAmount,
                      ),
                  ],
                ),
    );
    return true;
  }

  Future<String?> _saveImageBytesIfChanged(
    WidgetRef ref,
    PreparedMealEditResult result,
  ) async {
    if (!result.imageChanged || result.imageBytes == null) {
      return null;
    }
    final imageAssetId = _preparedMealImageAssetUuid.v4();
    final imageRef = localImageAssetRef(imageAssetId);
    await ref
        .read(localImageStoreProvider)
        .saveBytes(imageRef: imageRef, bytes: result.imageBytes!);
    ref.invalidate(localImageBytesProvider(imageRef));
    return imageAssetId;
  }

  /// Saves a meal as a reusable prepared meal template.
  Future<bool> saveTemplate({
    required BuildContext context,
    required WidgetRef ref,
    required PreparedMeal meal,
  }) async {
    final templatesController = ref.read(
      preparedMealTemplatesControllerProvider.notifier,
    );
    final result = await templatesController.saveTemplateFromMeal(meal);
    final templateId = result.templateId;
    if (!result.isSuccess || templateId == null || !context.mounted) {
      return result.isSuccess;
    }

    final container = ProviderScope.containerOf(context, listen: false);
    ScaffoldMessenger.of(context).showAppSnackBar(
      AppLocalizations.of(context)!.preparedMealTemplateSavedMessage,
      onUndo: () => container
          .read(preparedMealTemplatesControllerProvider.notifier)
          .deleteTemplate(templateId),
    );
    return true;
  }
}
