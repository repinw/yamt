import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/home/widgets/home_shell_chrome.dart'
    show HomeTabType;
import 'package:yamt/features/home/widgets/home_shell_tab_top_chrome.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_templates_controller.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/'
    'kitchen_utensils_button.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_card.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_recipe_import_button.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_recipe_template_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines meal templates page.
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
        : const [
            HomeShellTabTopChrome(
              tab: HomeTabType.cookbook,
              actions: [
                KitchenUtensilsButton(),
                MealTemplateRecipeImportButton(),
              ],
            ),
          ];

    return Scaffold(
      appBar: includeAppBar
          ? AppBar(
              title: Text(l10n.preparedMealTemplatesPageTitle),
              actions: const [
                KitchenUtensilsButton(),
                MealTemplateRecipeImportButton(),
              ],
            )
          : null,
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return CustomScrollView(
              slivers: [
                ...topChromeSlivers,
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: AppInsets.pageLarge,
                      child: Text(
                        l10n.preparedMealTemplatesEmptyState,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return CustomScrollView(
            slivers: [
              ...topChromeSlivers,
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  includeAppBar
                      ? AppSpacing.xxl
                      : AppSizes.homeShellBottomBarClearance,
                ),
                sliver: SliverList.separated(
                  itemCount: templates.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.lg),
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
                ),
              ),
            ],
          );
        },
        loading: () => CustomScrollView(
          slivers: [
            ...topChromeSlivers,
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: SizedBox.square(
                  dimension: AppSizes.inlineProgressIndicator,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.progressStrokeWidth,
                  ),
                ),
              ),
            ),
          ],
        ),
        error: (error, stackTrace) {
          return CustomScrollView(
            slivers: [
              ...topChromeSlivers,
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
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
                ),
              ),
            ],
          );
        },
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
