import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/macro_grams.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_step_foot.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Guten Appetit!" after "In den Vorrat legen": what lies in the Vorrat now
/// ([KochmodusView.finished]), each meal with the kcal and macros of one
/// portion, piece or can as it was booked, "Jetzt essen", which opens the
/// first meal's page in the Vorrat, and "Zum Kochbuch".
///
/// Both leave the cooking page with a go; nothing waits for the push that
/// opened it.
class KochmodusDoneView extends StatelessWidget {
  /// Creates the step of [view] for the cooking of [target].
  const new({required this.target, required this.view, super.key});

  /// Key of "Jetzt essen".
  static const eatKey = ValueKey<String>('kochmodus-done-eat');

  /// Key of "Zum Kochbuch".
  static const cookbookKey = ValueKey<String>('kochmodus-done-cookbook');

  /// What the page cooks; actions go to its controller.
  final KochmodusTarget target;

  /// The cooking as it is now.
  final KochmodusView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final finished = view.finished;
    if (finished == null) return const SizedBox.shrink();
    final first = finished.meals.firstOrNull;
    final sentenceStyle = textTheme.bodyLarge?.copyWith(color: colors.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: AppInsets.pageLarge,
              child: Column(
                spacing: AppSpacing.lg,
                children: [
                  Text(
                    l10n.kochmodusDoneTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  for (final meal in finished.meals)
                    _DoneMeal(meal: meal, style: sentenceStyle),
                  if (finished.inCookbook)
                    Text(
                      l10n.kochmodusDoneInCookbook,
                      textAlign: TextAlign.center,
                      style: sentenceStyle,
                    ),
                ],
              ),
            ),
          ),
        ),
        KochmodusStepFoot(
          children: [
            if (first != null)
              FilledButton(
                key: eatKey,
                onPressed: () =>
                    context.go(AppRoutes.homeInventoryMealPath(first.id)),
                style: KochmodusStepFoot.mainButtonStyle(context),
                child: Text(l10n.kochmodusDoneEat),
              ),
            OutlinedButton(
              key: cookbookKey,
              onPressed: () => context.go(AppRoutes.homeInventoryTemplates),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppGraphit.buttonHeight),
              ),
              child: Text(l10n.kochmodusBackToCookbook),
            ),
          ],
        ),
      ],
    );
  }
}

// One meal of the run: its sentence ("8 Stück Pfannkuchen liegen jetzt im
// Vorrat.") and, when the meal has nutrition, the kcal and macros of one
// portion, piece or can, centered.
class _DoneMeal extends StatelessWidget {
  const new({required this.meal, required this.style});

  final KochmodusDoneMeal meal;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final (count, name) = (meal.count, meal.name);
    return Column(
      spacing: AppSpacing.sm,
      children: [
        Text(
          switch (meal.serving) {
            KochmodusServing.portion => l10n.kochmodusDonePortions(count, name),
            KochmodusServing.piece => l10n.kochmodusDonePieces(count, name),
            KochmodusServing.can => l10n.kochmodusDoneCans(count, name),
          },
          textAlign: TextAlign.center,
          style: style,
        ),
        if (meal.perServing case final serving?) ...[
          Text(
            switch (meal.serving) {
              KochmodusServing.portion => l10n.kochmodusDoneKcalPerPortion(
                serving.kcal,
              ),
              KochmodusServing.piece => l10n.kochmodusDoneKcalPerPiece(
                serving.kcal,
              ),
              KochmodusServing.can => l10n.kochmodusDoneKcalPerCan(
                serving.kcal,
              ),
            },
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: colors.ink),
          ),
          MacroGrams.columns(
            protein: serving.protein,
            carbs: serving.carbs,
            fat: serving.fat,
            centered: true,
          ),
        ],
      ],
    );
  }
}
