import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_templates_controller.dart';
import 'package:yamt/features/meal_templates/presentation/models/'
    'meal_template_import_review_args.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines meal template import review page.
class MealTemplateImportReviewPage extends ConsumerStatefulWidget {
  /// The meal template import review page.
  const MealTemplateImportReviewPage({required this.args, super.key});

  /// The args.
  final MealTemplateImportReviewArgs args;

  @override
  ConsumerState<MealTemplateImportReviewPage> createState() =>
      _MealTemplateImportReviewPageState();
}

class _MealTemplateImportReviewPageState
    extends ConsumerState<MealTemplateImportReviewPage> {
  var _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final importedRecipe = widget.args.importedRecipe;
    final title = _resolvedName();
    final portions = _resolvedPortions();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preparedMealTemplateImportReviewTitle)),
      body: ListView(
        padding: AppInsets.pageLarge,
        children: [
          if (importedRecipe.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: AppCachedNetworkImage(
                imageUrl: importedRecipe.imageUrl!,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            importedRecipe.recipeUrl,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.preparedMealTemplatePortions(portions),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            l10n.preparedMealIngredientsTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          ...importedRecipe.ingredients.map(
            (ingredient) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text('• $ingredient'),
            ),
          ),
          if (importedRecipe.instructionsPreview.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxxl),
            Text(
              l10n.preparedMealTemplateImportReviewInstructionsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            ...importedRecipe.instructionsPreview.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text('• $step'),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxxxl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : context.pop,
                  child: Text(l10n.inventoryReceiptReviewCancelAction),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveTemplate,
                  child: Text(
                    _isSaving
                        ? l10n.preparedMealTemplateImportReviewSavingAction
                        : l10n.preparedMealSaveTemplateAction,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _resolvedName() {
    final trimmedName = widget.args.preferredName.trim();
    if (trimmedName.isNotEmpty) {
      return trimmedName;
    }
    return widget.args.importedRecipe.title;
  }

  int _resolvedPortions() {
    final preferredPortions = widget.args.preferredPortions;
    if (preferredPortions != null && preferredPortions > 0) {
      return preferredPortions;
    }
    return widget.args.importedRecipe.servings;
  }

  Future<void> _saveTemplate() async {
    setState(() {
      _isSaving = true;
    });

    final result = await ref
        .read(preparedMealTemplatesControllerProvider.notifier)
        .saveImportedRecipeTemplate(
          importedRecipe: widget.args.importedRecipe,
          name: widget.args.preferredName,
          totalPortions: widget.args.preferredPortions,
        );
    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    final l10n = AppLocalizations.of(context)!;
    if (result.isSuccess) {
      _showSnackBar(l10n.preparedMealTemplateSavedMessage);
      context.pop();
      return;
    }

    _showSnackBar(_saveFailureMessage(l10n, result));
  }

  String _saveFailureMessage(
    AppLocalizations l10n,
    PreparedMealTemplateSaveResult result,
  ) {
    return switch (result.failureReason) {
      PreparedMealTemplateSaveFailureReason.recipeLoadFailed =>
        l10n.preparedMealTemplateRecipeImportFailedMessage,
      PreparedMealTemplateSaveFailureReason.invalidInput ||
      PreparedMealTemplateSaveFailureReason.saveFailed ||
      null => l10n.preparedMealTemplateCreateFailedMessage,
    };
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
