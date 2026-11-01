import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/cooking/application/cook_recipe_source.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';
import 'package:yamt/features/cooking/presentation/controllers/cook_finish_controller.dart';
import 'package:yamt/features/cooking/presentation/controllers/cook_session_controller.dart';
import 'package:yamt/features/cooking/presentation/controllers/cook_view_builder.dart';
import 'package:yamt/features/cooking/presentation/models/cook_view.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_finish_error_text.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_found_step.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_item_picker_sheet.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_open_step.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_portion_step.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_pot_step.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_recipe_step.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_top_bar.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Cooking a recipe in the new cooking flow: recipe, assigning each line
/// from the Vorrat or leaving it out, the pot, and portioning into the
/// Vorrat. The cooking lives only while the page is open.
class CookPage extends ConsumerWidget {
  /// Creates the page for the recipe [recipeId].
  const new({required this.recipeId, super.key});

  /// The recipe.
  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final view = ref.watch(cookViewProvider(recipeId, l10n.localeName));
    return Scaffold(
      backgroundColor: FoodLabelColors.of(context).paper,
      body: SafeArea(
        child: view.when(
          data: (view) => view == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Text(
                      l10n.cookRecipeGone,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _CookBody(view: view),
          loading: () => const AppLoadingView(),
          error: (_, _) => AppErrorRetryView(
            message: l10n.cookLoadFailed,
            retryLabel: l10n.inventoryRetryAction,
            onRetry: () => ref
              ..invalidate(cookRecipeTemplateProvider(recipeId))
              ..invalidate(inventoryQuickEatItemsProvider),
          ),
        ),
      ),
    );
  }
}

class _CookBody extends ConsumerWidget {
  const new({required this.view});

  final CookView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeId = view.recipe.id;
    CookSessionController session() =>
        ref.read(cookSessionControllerProvider(recipeId).notifier);
    final busy = ref.watch(cookFinishControllerProvider(recipeId)).isLoading;
    final step = view.session.step;
    final steps = [
      CookStep.recipe,
      if (view.foundLines.isNotEmpty) CookStep.found,
      if (view.openLines.isNotEmpty) CookStep.open,
      CookStep.pot,
      CookStep.portion,
    ];
    final index = steps.indexOf(step).clamp(0, steps.length - 1);
    void next() => session().goTo(steps[index + 1]);
    void back() =>
        index == 0 ? context.pop() : session().goTo(steps[index - 1]);

    Future<void> pick(CookLineView line, {bool onSecondPage = false}) async {
      final takes = await showCookItemPicker(context: context, line: line);
      if (takes != null) {
        session().assign(line.line.id, takes, onSecondPage: onSecondPage);
      }
    }

    return PopScope(
      canPop: index == 0 && !busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy && index > 0) back();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CookTopBar(step: steps[index], onBack: busy ? null : back),
          Expanded(
            child: switch (steps[index]) {
              CookStep.recipe => CookRecipeStep(
                view: view,
                onPortions: (portions) => session().setPortions(portions),
                onNext: next,
              ),
              CookStep.found => CookFoundStep(
                view: view,
                onAccept: (line) => session().assign(line.line.id, [
                  for (final take in line.suggestion)
                    (itemId: take.item.id, amount: take.amount),
                ]),
                onReject: (line) => session().reject(line.line.id),
                onReopen: (line) => session().reopen(line.line.id),
                onPick: (line) => unawaited(pick(line)),
                onNext: next,
              ),
              CookStep.open => CookOpenStep(
                view: view,
                onAssign: (line) => unawaited(pick(line, onSecondPage: true)),
                onOmit: (line) => session().omit(line.line.id),
                onNext: next,
              ),
              CookStep.pot => CookPotStep(
                pot: view.session.pot,
                onPot: (pot) => session().choosePot(pot),
                onNext: next,
              ),
              CookStep.portion => CookPortionStep(
                view: view,
                busy: busy,
                onFinish: (portioning) =>
                    unawaited(_finish(context, ref, portioning)),
              ),
            },
          ),
        ],
      ),
    );
  }

  Future<void> _finish(
    BuildContext context,
    WidgetRef ref,
    CookPortioning portioning,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(
      cookFinishControllerProvider(view.recipe.id).notifier,
    );
    final error = await controller.finish(
      recipe: view.recipe,
      session: view.session,
      portioning: portioning,
    );
    final name = portioning.name.trim();
    if (error == null) {
      messenger.showAppSnackBar(
        l10n.cookSaved(name.isEmpty ? view.recipe.name : name),
      );
      if (context.mounted) context.pop();
      return;
    }
    messenger.showAppSnackBar(
      cookFinishErrorText(l10n, error),
      tone: AppSnackBarTone.error,
    );
  }
}
