import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/core/widgets/macro_grams.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_card_answers.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The card of "Was hast du da?" once nothing is left to answer. With lines
/// on the shopping list: "Fast alles da", how many, and "Erst einkaufen",
/// which pauses and goes back to the recipe page, whose snack bar opens the
/// shopping list. Else "Alles bereit" with the portions, the energy and the
/// macros of one portion when they are known ("≈" while a line's weight is
/// only estimated, `KochmodusView.estimated`), "Mit Anleitung" when the
/// recipe has instructions, and "Kochen", which goes on to the cooking page.
/// "Später" under both only closes the page.
class KochmodusReadyCard extends StatelessWidget {
  /// Creates the card of [view] for the cooking of [target].
  const new({required this.target, required this.view, super.key});

  /// Key of "Mit Anleitung".
  static const guideKey = ValueKey<String>('kochmodus-assign-guide');

  /// Key of "Später", here and beside the progress while lines are open.
  static const laterKey = ValueKey<String>('kochmodus-assign-later');

  /// Key of "Kochen" or "Erst einkaufen".
  static const mainKey = ValueKey<String>('kochmodus-assign-main');

  /// What the page cooks; actions go to its controller.
  final KochmodusTarget target;

  /// The cooking as it is now.
  final KochmodusView view;

  /// "Später": closes the page; the run keeps its reservations.
  static void later(BuildContext context) {
    final message = AppLocalizations.of(context)!.kochmodusAssignLaterDone;
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger.showAppSnackBar(message);
  }

  Future<void> _pause(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final paused = await KochmodusActionFlow.run(
      context,
      target,
      (controller) => controller.pauseForShopping(),
      failed: l10n.kochmodusPauseFailed,
    );
    if (!paused || !context.mounted) return;
    context.pop();
    if (messenger.mounted) {
      messenger.showAppSnackBar(
        l10n.kochmodusPausedForShopping,
        action: (
          label: l10n.kochmodusShoppingListAction,
          onPressed: () => unawaited(router.push(AppRoutes.homeShopping)),
        ),
      );
    }
  }

  // The cooking page replaces this page and opens on "Töpfe".
  Future<void> _cook(BuildContext context) async {
    final cooking = await KochmodusActionFlow.run(
      context,
      target,
      (controller) => controller.toPots(),
    );
    if (!cooking || !context.mounted) return;
    context.pushReplacement(AppRoutes.homeCookRunPath(view.run.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final toBuy = view.shopping.length;
    final buying = toBuy > 0;
    final portion = view.perPortion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Text(
          buying
              ? l10n.kochmodusAssignAlmostTitle
              : l10n.kochmodusAssignSettledTitle,
          style: textTheme.headlineMedium?.copyWith(color: colors.ink),
        ),
        Text(
          buying
              ? l10n.kochmodusAssignToBuy(toBuy)
              : l10n.kochmodusAssignReadyText(view.run.portions),
          style: textTheme.bodyLarge?.copyWith(color: colors.muted),
        ),
        if (!buying && portion != null) ...[
          Text(
            view.estimated.isEmpty
                ? l10n.kochmodusAssignKcalPerPortion(portion.kcal)
                : l10n.kochmodusAssignKcalPerPortionEstimated(portion.kcal),
            style: textTheme.titleMedium?.copyWith(color: colors.ink),
          ),
          MacroGrams.columns(
            protein: portion.protein,
            carbs: portion.carbs,
            fat: portion.fat,
          ),
        ],
        if (!buying && view.guideVisible)
          AppSwitchListTile(
            key: guideKey,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.kochmodusAssignWithGuide),
            subtitle: Text(l10n.kochmodusAssignWithGuideSub),
            value: view.run.withGuide,
            onChanged: (on) => unawaited(
              KochmodusActionFlow.run(
                context,
                target,
                (controller) => controller.setGuide(on: on),
              ),
            ),
          ),
        FilledButton(
          key: mainKey,
          onPressed: view.busy
              ? null
              : () => unawaited(buying ? _pause(context) : _cook(context)),
          style: KochmodusCardAnswers.mainStyle(context),
          child: Text(
            buying ? l10n.kochmodusAssignPause : l10n.kochmodusAssignCook,
          ),
        ),
        TextButton(
          key: laterKey,
          onPressed: () => later(context),
          child: Text(l10n.kochmodusAssignLater),
        ),
      ],
    );
  }
}
