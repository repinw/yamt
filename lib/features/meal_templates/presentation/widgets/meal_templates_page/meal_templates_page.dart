import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/home_shell_tab_top_chrome.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_button/ai_chef_button.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_templates_controller.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/'
    'kitchen_utensils_button.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_recipe_import_button.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_recipe_template_sheet.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_templates_page/meal_templates_empty_state.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_templates_page/meal_templates_error_state.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_templates_page/meal_templates_grid.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_templates_page/meal_templates_loading_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines meal templates page.
@Dependencies([InventoryItemsController])
class MealTemplatesPage extends ConsumerWidget {
  /// The meal templates page.
  const MealTemplatesPage({super.key, this.includeAppBar = true});

  /// Whether this page should render its own app bar.
  final bool includeAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(preparedMealTemplatesControllerProvider, _logLoadErrorOnce);

    final l10n = AppLocalizations.of(context)!;
    final templatesController = ref.read(
      preparedMealTemplatesControllerProvider.notifier,
    );
    final templatesAsync = ref.watch(preparedMealTemplatesControllerProvider);

    final topChromeSlivers = includeAppBar
        ? const <Widget>[]
        : [
            HomeShellTabTopChrome(
              title: l10n.homeCookbook,
              actions: const [
                AiChefButton(),
                KitchenUtensilsButton(),
                MealTemplateRecipeImportButton(),
              ],
            ),
          ];

    final bodySliver = templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: MealTemplatesEmptyState(),
          );
        }

        return MealTemplatesGrid(
          templates: templates,
          includeAppBar: includeAppBar,
          onOpen: (template) => _openTemplateDetail(
            context: context,
            templateId: template.id,
          ),
          onEdit: (template) => _editTemplate(
            context: context,
            templatesController: templatesController,
            template: template,
          ),
          onDelete: (templateId) => _deleteTemplate(
            context: context,
            templatesController: templatesController,
            templateId: templateId,
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: MealTemplatesLoadingState(),
      ),
      error: (error, stackTrace) => SliverFillRemaining(
        hasScrollBody: false,
        child: MealTemplatesErrorState(
          onRetry: templatesController.refresh,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: includeAppBar
          ? AppBar(
              title: Text(l10n.preparedMealTemplatesPageTitle),
              actions: const [
                AiChefButton(),
                KitchenUtensilsButton(),
                MealTemplateRecipeImportButton(),
              ],
            )
          : null,
      body: CustomScrollView(
        slivers: [
          ...topChromeSlivers,
          bodySliver,
        ],
      ),
    );
  }

  void _openTemplateDetail({
    required BuildContext context,
    required String templateId,
  }) {
    unawaited(
      context.push(AppRoutes.homeInventoryTemplateDetailPath(templateId)),
    );
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
    required PreparedMealTemplatesController templatesController,
    required String templateId,
  }) async {
    final deleted = await templatesController.deleteTemplate(templateId);
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

  Future<bool> _editTemplate({
    required BuildContext context,
    required PreparedMealTemplatesController templatesController,
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

    final result = await templatesController.updateRecipeTemplate(
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
