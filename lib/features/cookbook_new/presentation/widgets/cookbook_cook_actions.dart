import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/home_action_entry.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_button/ai_chef_button.dart';
import 'package:yamt/features/meal_templates/presentation/'
    'meal_template_recipe_import_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Keys of the Kochbuch cook actions.
abstract final class CookbookCookActionKeys {
  /// Entry that starts free cooking.
  static const freeCooking = ValueKey<String>('cookbook-free-cooking');

  /// Entry that imports a recipe from a link.
  static const link = ValueKey<String>('cookbook-link');

  /// Entry that asks the AI for a recipe idea.
  static const ai = ValueKey<String>('cookbook-ai');
}

/// The ways to start cooking: free cooking, a recipe from a link, and an AI
/// idea.
List<HomeActionSection> cookbookCookActions(
  BuildContext context,
  WidgetRef ref,
) {
  final l10n = AppLocalizations.of(context)!;
  return [
    HomeActionSection(
      title: l10n.homeActionCook,
      entries: [
        HomeActionEntry(
          key: CookbookCookActionKeys.freeCooking,
          icon: Icons.mic_rounded,
          title: l10n.cookbookFreeCookingAction,
          description: l10n.cookbookFreeCookingDescription,
          onSelected: () =>
              unawaited(context.push<void>(AppRoutes.homeFreeCooking)),
        ),
        HomeActionEntry(
          key: CookbookCookActionKeys.link,
          icon: Icons.add_link_rounded,
          title: l10n.preparedMealTemplateAddRecipeAction,
          description: l10n.preparedMealTemplateAddRecipeDescription,
          onSelected: () => startRecipeTemplateImport(context, ref),
        ),
        HomeActionEntry(
          key: CookbookCookActionKeys.ai,
          icon: Icons.auto_awesome_rounded,
          title: l10n.aiChefIdeaTitle,
          description: l10n.aiChefIdeaDescription,
          onSelected: () => openAiChef(context),
        ),
      ],
    ),
  ];
}
