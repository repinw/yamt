import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/diary/application/diary_plan_ingredients_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_plan_details_controller.dart';

part 'diary_plan_ingredient_rows_provider.g.dart';

/// The recipe lines of the plan on its details page, each with the plan
/// foods it takes, and the foods no line takes, or null when the plan comes
/// from no Kochbuch recipe.
@riverpod
Future<DiaryPlanIngredientRows?> diaryPlanIngredientRows(
  Ref ref,
  String planId,
  DateTime planDay,
  DateTime today,
) async {
  final plan = ref.watch(
    diaryPlanDetailsControllerProvider(
      planId,
      planDay,
      today,
    ).select((state) => state?.preview),
  );
  final templateId = plan?.bundleSourceTemplateId;
  if (plan == null || templateId == null) {
    return null;
  }
  final recipe = await ref.watch(
    diaryPlanIngredientsProvider(templateId).future,
  );
  return recipe == null ? null : diaryPlanIngredientLines(plan, recipe.lines);
}
