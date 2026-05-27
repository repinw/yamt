import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';
import 'package:yamt/features/meal_templates/presentation/models/'
    'meal_template_import_review_args.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_recipe_template_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Premium, rich empty state for the cookbook page.
class MealTemplatesEmptyState extends ConsumerWidget {
  /// Creates a premium empty state widget.
  const MealTemplatesEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final borderRadius = BorderRadius.circular(AppEditorial.cardRadius);

    return Center(
      child: SingleChildScrollView(
        padding: AppInsets.pageLarge,
        child: DecoratedBox(
          decoration: AppEditorialSurfaces.liftedCardDecoration(
            colors,
            borderRadius: borderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _GlowingHalo(icon: Icons.restaurant_menu_rounded),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.homeCookbook,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.preparedMealTemplatesEmptyState,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: () => unawaited(
                    _createTemplateFromRecipe(
                      context: context,
                      importer: ref.read(preparedMealRecipeImporterProvider),
                      localeName: l10n.localeName,
                    ),
                  ),
                  icon: const Icon(Icons.add_link_rounded),
                  label: Text(l10n.preparedMealTemplateAddRecipeAction),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createTemplateFromRecipe({
    required BuildContext context,
    required PreparedMealRecipeImporter importer,
    required String localeName,
  }) async {
    final draft = await showPreparedMealRecipeTemplateSheet(context);
    if (!context.mounted || draft == null) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final importedRecipe = await importer.importRecipe(
      draft.recipeUrl,
      localeName: localeName,
    );
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

    unawaited(
      context.push(
        AppRoutes.homeInventoryTemplateImportReview,
        extra: MealTemplateImportReviewArgs(
          importedRecipe: importedRecipe,
          preferredName: draft.name,
          preferredPortions: draft.totalPortions,
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GlowingHalo extends StatelessWidget {
  const _GlowingHalo({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;

    final blurRadius = isDark
        ? AppEditorial.emptyStateActionDarkBlurRadius
        : AppEditorial.emptyStateActionLightBlurRadius;
    final spreadRadius = isDark
        ? AppEditorial.emptyStateActionDarkSpreadRadius
        : AppEditorial.emptyStateActionLightSpreadRadius;

    return Container(
      width: AppEditorial.emptyStateActionHighlightSize,
      height: AppEditorial.emptyStateActionHighlightSize,
      alignment: Alignment.center,
      child: Container(
        width: AppEditorial.emptyStateActionHaloSize,
        height: AppEditorial.emptyStateActionHaloSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: isDark ? 0.35 : 0.2),
              blurRadius: blurRadius,
              spreadRadius: spreadRadius,
            ),
          ],
          color: colors.primaryContainer.withValues(alpha: 0.8),
        ),
        child: Icon(
          icon,
          size: 32,
          color: colors.primary,
        ),
      ),
    );
  }
}
