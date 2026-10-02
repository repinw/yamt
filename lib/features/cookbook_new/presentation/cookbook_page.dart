import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/core/widgets/home_shell_tab_top_chrome.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_sections.dart';
import 'package:yamt/features/inventory/presentation/'
    'prepared_meal_detail_flow.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/'
    'kitchen_utensils_button.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Kochbuch tab: meals still in the pot, Vorlagen combined from the Vorrat,
/// and recipes with the stock state of their ingredients.
class CookbookPage extends ConsumerWidget {
  /// Creates the Kochbuch page.
  const new({super.key});

  /// Key of the retry button after a load failure.
  static const retryKey = ValueKey<String>('cookbook-retry');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = cookbookControllerProvider(l10n.localeName);
    final overviewAsync = ref.watch(provider);
    final recipeCount = overviewAsync.asData?.value.recipes.length;

    final body = overviewAsync.when(
      data: (overview) => SliverToBoxAdapter(
        child: CookbookSections(
          overview: overview,
          onContinueMeal: (meal) => unawaited(
            meal.isInPot
                ? context.push(AppRoutes.homeCookedMealPath(meal.id))
                : PreparedMealDetailFlow.open(
                    context: context,
                    ref: ref,
                    meal: meal,
                  ),
          ),
          onCreateTemplate: () => context.go(AppRoutes.homeInventory),
          onOpenTemplate: (template) => unawaited(
            context.push(
              AppRoutes.homeInventoryTemplateDetailPath(template.id),
            ),
          ),
        ),
      ),
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: AppLoadingView(),
      ),
      error: (error, stackTrace) => SliverFillRemaining(
        hasScrollBody: false,
        child: AppErrorRetryView(
          retryButtonKey: retryKey,
          message: l10n.cookbookLoadFailed,
          retryLabel: l10n.inventoryRetryAction,
          onRetry: () => ref.read(provider.notifier).retry(),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          HomeShellTabTopChrome(
            title: l10n.homeCookbook,
            kicker: recipeCount == null
                ? null
                : l10n.cookbookRecipeCount(recipeCount),
            tools: const [KitchenUtensilsButton()],
          ),
          body,
        ],
      ),
    );
  }
}
