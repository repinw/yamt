import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_stock_picker_sheet.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_plan_details_controller.dart';
import 'package:yamt/features/inventory/application/template_plan_ingredients.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Lets the user pick another Vorrat item for [line] of the recipe
/// [templateId] and saves it on the recipe through [controller], so the
/// plan on the page and the recipe's plans without choices of their own
/// take it. Only Vorrat items: a plan needs one to count. A failed save
/// shows a snack bar.
Future<void> pickDiaryPlanIngredientFlow(
  BuildContext context,
  WidgetRef ref, {
  required DiaryPlanDetailsControllerProvider controller,
  required String templateId,
  required TemplatePlanIngredient line,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final failure = AppLocalizations.of(context)!.diaryPlanIngredientSaveFailed;
  final current = line.items.firstOrNull?.id;
  final pick = await showRecipeStockPicker(
    context: context,
    foodName: line.ingredient.trim(),
    candidates: line.candidates,
    selectedId: current,
    canPickNone: false,
  );
  final itemId = pick?.itemId;
  // A page closed meanwhile has no plan to change.
  if (itemId == null || itemId == current || !context.mounted) {
    return;
  }
  final saved = await ref
      .read(controller.notifier)
      .pickIngredientItem(templateId, line.ingredient, itemId);
  if (!saved) {
    messenger.showAppSnackBar(failure, tone: AppSnackBarTone.error);
  }
}
