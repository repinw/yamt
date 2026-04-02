import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_templates_controller.dart';
import 'package:yamt/features/meal_templates/presentation/models/'
    'meal_template_import_review_args.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_card.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_recipe_template_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

class MealTemplatesPage extends ConsumerWidget {
  const MealTemplatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(preparedMealTemplatesControllerProvider, _logLoadErrorOnce);

    final l10n = AppLocalizations.of(context)!;
    final templatesController = ref.read(
      preparedMealTemplatesControllerProvider.notifier,
    );
    final templatesAsync = ref.watch(preparedMealTemplatesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.preparedMealTemplatesPageTitle),
        actions: [
          IconButton(
            tooltip: l10n.preparedMealTemplateAddRecipeAction,
            onPressed: () =>
                _createTemplateFromRecipe(context: context, ref: ref),
            icon: const Icon(Icons.add_link_rounded),
          ),
        ],
      ),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return Center(
              child: Padding(
                padding: AppInsets.pageLarge,
                child: Text(
                  l10n.preparedMealTemplatesEmptyState,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            itemCount: templates.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
            itemBuilder: (context, index) {
              final template = templates[index];
              return PreparedMealTemplateCard(
                template: template,
                onOpenPressed: () => _openTemplateDetail(
                  context: context,
                  templateId: template.id,
                ),
                onEditPressed: (template) => _editTemplate(
                  context: context,
                  ref: ref,
                  template: template,
                ),
                onDeletePressed: (templateId) => _deleteTemplate(
                  context: context,
                  ref: ref,
                  templateId: templateId,
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: SizedBox.square(
            dimension: AppSizes.inlineProgressIndicator,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.progressStrokeWidth,
            ),
          ),
        ),
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: AppInsets.pageLarge,
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: AppInsets.card,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.wifi_tethering_error_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.preparedMealTemplatesLoadFailed,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: templatesController.refresh,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.inventoryRetryAction),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openTemplateDetail({
    required BuildContext context,
    required String templateId,
  }) {
    context.push(AppRoutes.homeInventoryTemplateDetailPath(templateId));
  }

  void _logLoadErrorOnce(
    AsyncValue<List<PreparedMeal>>? previous,
    AsyncValue<List<PreparedMeal>> next,
  ) {
    final nextError = next.asError;
    if (nextError == null) {
      return;
    }

    final previousError = previous?.asError;
    final unchangedError = identical(previousError?.error, nextError.error);
    final unchangedStack = previousError?.stackTrace == nextError.stackTrace;
    if (unchangedError && unchangedStack) {
      return;
    }

    developer.log(
      'Failed to load prepared meal templates.',
      name: 'PreparedMealTemplatesPage',
      error: nextError.error,
      stackTrace: nextError.stackTrace,
    );
  }

  Future<bool> _deleteTemplate({
    required BuildContext context,
    required WidgetRef ref,
    required String templateId,
  }) async {
    final deleted = await ref
        .read(preparedMealTemplatesControllerProvider.notifier)
        .deleteTemplate(templateId);
    if (!context.mounted) {
      return deleted;
    }
    if (!deleted) {
      return false;
    }

    _showSnackBar(
      context,
      AppLocalizations.of(context)!.preparedMealTemplateDeletedMessage,
    );
    return true;
  }

  Future<void> _createTemplateFromRecipe({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final draft = await showPreparedMealRecipeTemplateSheet(context);
    if (!context.mounted || draft == null) {
      return;
    }

    final importedRecipe = await ref
        .read(preparedMealRecipeImporterProvider)
        .importRecipe(draft.recipeUrl, localeName: l10n.localeName);
    if (!context.mounted) {
      return;
    }

    if (importedRecipe == null) {
      _showSnackBar(
        context,
        l10n.preparedMealTemplateRecipeImportFailedMessage,
      );
      return;
    }

    context.push(
      AppRoutes.homeInventoryTemplateImportReview,
      extra: MealTemplateImportReviewArgs(
        importedRecipe: importedRecipe,
        preferredName: draft.name,
        preferredPortions: draft.totalPortions,
      ),
    );
  }

  Future<bool> _editTemplate({
    required BuildContext context,
    required WidgetRef ref,
    required PreparedMeal template,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final draft = await showPreparedMealRecipeTemplateSheet(
      context,
      initialDraft: PreparedMealRecipeTemplateDraft(
        recipeUrl: template.recipeUrl ?? '',
        name: template.name,
        totalPortions: template.totalPortions,
      ),
      title: l10n.preparedMealTemplateRecipeEditSheetTitle,
      submitLabel: l10n.inventoryReceiptReviewEditAction,
    );
    if (!context.mounted || draft == null) {
      return false;
    }

    final result = await ref
        .read(preparedMealTemplatesControllerProvider.notifier)
        .updateRecipeTemplate(
          templateId: template.id,
          recipeUrl: draft.recipeUrl,
          name: draft.name,
          totalPortions: draft.totalPortions,
          localeName: l10n.localeName,
        );
    if (!context.mounted) {
      return result.isSuccess;
    }

    if (result.isSuccess) {
      _showSnackBar(context, l10n.preparedMealTemplateUpdatedMessage);
      return true;
    }

    _showSnackBar(context, _templateFailureMessage(l10n, result));
    return false;
  }

  String _templateFailureMessage(
    AppLocalizations l10n,
    PreparedMealTemplateSaveResult result,
  ) {
    return switch (result.failureReason) {
      PreparedMealTemplateSaveFailureReason.invalidInput =>
        l10n.preparedMealTemplateRecipeUrlInvalid,
      PreparedMealTemplateSaveFailureReason.recipeLoadFailed =>
        l10n.preparedMealTemplateRecipeImportFailedMessage,
      PreparedMealTemplateSaveFailureReason.saveFailed ||
      null => l10n.preparedMealTemplateCreateFailedMessage,
    };
  }

  void _showSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
