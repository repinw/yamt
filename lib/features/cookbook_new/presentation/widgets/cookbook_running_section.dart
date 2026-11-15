import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cookbook_new/domain/cookbook_overview.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_meal_picture.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_open_meal_card.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_running_card.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_section_title.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Läuft" in the Kochbuch: the household's cook runs with "Weiter", then
/// the meals of the old cooking that are still in the pot or have open rows.
class CookbookRunningSection extends StatelessWidget {
  /// Creates the section of [runs] and [openMeals].
  const new({
    required this.runs,
    required this.openMeals,
    required this.onContinueMeal,
    super.key,
  });

  /// Key of the "Weiter" button of the cook run [runId].
  static ValueKey<String> continueKey(String runId) =>
      ValueKey<String>('cookbook-run-continue-$runId');

  /// The household's cook runs.
  final List<CookbookRun> runs;

  /// Meals of the old cooking that are still in the pot or have open rows.
  final List<PreparedMeal> openMeals;

  /// Opens such a meal.
  final ValueChanged<PreparedMeal> onContinueMeal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xs,
      children: [
        CookbookSectionTitle(
          title: l10n.cookbookRunningTitle,
          caption: runs.isEmpty ? null : l10n.cookbookRunningCount(runs.length),
        ),
        for (final run in runs) _RunCard(row: run),
        if (openMeals.isNotEmpty) ...[
          if (runs.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          CookbookSectionTitle(
            title: l10n.cookbookOldMealsTitle(openMeals.length),
          ),
          for (final meal in openMeals)
            CookbookOpenMealCard(
              meal: meal,
              onContinue: () => onContinueMeal(meal),
            ),
        ],
      ],
    );
  }
}

class _RunCard extends ConsumerWidget {
  const new({required this.row});

  final CookbookRun row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final run = row.run;
    final now = ref.watch(clockProvider)();
    final status = switch (run.step) {
      CookRunStep.pots => l10n.cookbookRunStatusPots,
      // As the recipe page's status card says it.
      CookRunStep.assign when run.openCount > 0 => l10n.recipeLinesOpenTitle(
        run.openCount,
      ),
      CookRunStep.assign when run.shoppingCount > 0 => l10n.recipeLinesShopping(
        run.shoppingCount,
      ),
      CookRunStep.assign => l10n.recipeLinesReadyTitle,
      CookRunStep.paused => l10n.cookbookRunStatusPausedShopping(
        run.shoppingCount,
      ),
      CookRunStep.cook => switch (row.nextTimer) {
        final timer? => l10n.cookbookRunStatusCookTimer(
          CookbookRunningCard.timeOrDay(context, timer.endsAt, now),
        ),
        null when run.withGuide && run.steps.isNotEmpty =>
          l10n.cookbookRunStatusCookStep(run.guideStep + 1),
        null => l10n.cookbookRunStatusCook,
      },
      CookRunStep.portion => l10n.cookbookRunStatusPortion,
    };
    final starter = run.startedByName.trim();
    final who = row.startedByMe
        ? l10n.cookbookRunStartedByYou
        : starter.isEmpty
        ? l10n.cookbookRunStartedBySomeone
        : starter;
    // Free cooking has no name until it is portioned.
    final name = run.name.isEmpty ? l10n.cookbookRunFreeName : run.name;

    return CookbookRunningCard(
      picture: CookbookMealPicture.run(
        run,
        name: name,
        size: AppGraphit.buttonHeight,
      ),
      name: name,
      status: status,
      attention: run.step == CookRunStep.paused,
      detail: l10n.cookbookRunStartedBy(
        who,
        CookbookRunningCard.timeOrDay(context, run.startedAt, now),
      ),
      action: l10n.cookbookContinueAction,
      actionKey: CookbookRunningSection.continueKey(run.id),
      // A recipe run whose lines need assigning goes on with "Zuweisen".
      onAction: () => unawaited(
        context.push(switch (run) {
          CookRun(needsAssigning: true, :final recipeId?) =>
            AppRoutes.homeCookPath(recipeId),
          _ => AppRoutes.homeCookRunPath(run.id),
        }),
      ),
    );
  }
}
