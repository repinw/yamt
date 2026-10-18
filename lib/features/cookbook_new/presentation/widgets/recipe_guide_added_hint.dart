import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "2 Zusätze aus dem Kochhelfer" on the recipe page, with an undo that
/// takes them out again. Nothing while the Kochhelfer added nothing.
class RecipeGuideAddedHint extends ConsumerWidget {
  /// Creates the hint for the recipe [recipeId].
  const new({required this.recipeId, super.key});

  /// Key of the hint text.
  static const textKey = ValueKey<String>('recipe-guide-added');

  /// Key of the undo button.
  static const undoKey = ValueKey<String>('recipe-guide-added-undo');

  /// The recipe.
  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = recipeControllerProvider(recipeId);
    final count = ref.watch(provider.select((d) => d.fromGuide.length));
    if (count == 0) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    // Read together, so "Rückgängig" says what it takes back.
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.recipeGuideAdded(count),
                key: textKey,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: FoodLabelColors.of(context).muted),
              ),
            ),
            TextButton(
              key: undoKey,
              onPressed: () => ref.read(provider.notifier).undoGuideAdded(),
              child: Text(l10n.commonUndoAction),
            ),
          ],
        ),
      ),
    );
  }
}
