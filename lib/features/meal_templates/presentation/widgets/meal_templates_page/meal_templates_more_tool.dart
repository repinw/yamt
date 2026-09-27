import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/home_more_sheet.dart';
import 'package:yamt/core/widgets/home_more_tool.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_button/ai_chef_button.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_recipe_import_button.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Mehr tool of the cookbook tab: its sheet explains the cookbook tools
/// in one line each.
class MealTemplatesMoreTool extends ConsumerWidget {
  /// Creates the cookbook Mehr tool.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return HomeMoreTool(
      title: l10n.homeCookbook,
      entries: [
        HomeMoreEntry(
          icon: Icons.auto_awesome_rounded,
          title: l10n.aiChefIdeaTitle,
          description: l10n.aiChefIdeaDescription,
          onSelected: () => openAiChef(context),
        ),
        HomeMoreEntry(
          icon: Icons.kitchen_rounded,
          title: l10n.kitchenUtensilsOpenAction,
          description: l10n.kitchenUtensilsDescription,
          onSelected: () =>
              unawaited(context.push(AppRoutes.homeKitchenUtensils)),
        ),
        HomeMoreEntry(
          icon: Icons.add_link_rounded,
          title: l10n.preparedMealTemplateAddRecipeAction,
          description: l10n.preparedMealTemplateAddRecipeDescription,
          onSelected: () => startRecipeTemplateImport(context, ref),
        ),
      ],
    );
  }
}
