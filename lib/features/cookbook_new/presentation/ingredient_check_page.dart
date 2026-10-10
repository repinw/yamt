import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/ingredient_check_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/ingredient_check_view.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_found_list.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_missing_list.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_summary.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_top_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_stock_picker_sheet.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/presentation/models/prepared_meal_food_source.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_pending_food_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum _Step { found, missing, summary }

/// "Zutaten prüfen" for a recipe: the ingredients the Vorrat holds, the ones
/// it lacks, and a summary. "Fertig" puts the chosen ones on the shopping
/// list, saves the Vorrat items and ignored ingredients on the recipe, and
/// goes back to the recipe page. Closing the check changes nothing.
class IngredientCheckPage extends ConsumerStatefulWidget {
  /// Creates the check of the recipe [recipeId].
  const new({required this.recipeId, super.key});

  /// Key of the button at the bottom: "Weiter", or "Fertig" at the end.
  static const nextKey = ValueKey<String>('ingredient-check-next');

  /// Key of the back button at the top.
  static const backKey = ValueKey<String>('ingredient-check-back');

  /// The recipe.
  final String recipeId;

  @override
  ConsumerState<IngredientCheckPage> createState() =>
      _IngredientCheckPageState();
}

class _IngredientCheckPageState extends ConsumerState<IngredientCheckPage> {
  var _step = 0;
  var _isBusy = false;

  IngredientCheckController get _controller =>
      ref.read(ingredientCheckControllerProvider(widget.recipeId).notifier);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final checkAsync = ref.watch(
      ingredientCheckViewProvider(widget.recipeId, l10n.localeName),
    );

    // "Fertig" and "Hab ich" finish before the check closes.
    return PopScope(
      canPop: !_isBusy,
      child: Scaffold(
        backgroundColor: FoodLabelColors.of(context).paper,
        body: SafeArea(
          child: checkAsync.when(
            data: (check) => check == null
                ? Center(child: Text(l10n.recipeNotFound))
                : _body(check),
            error: (_, _) => AppErrorRetryView(
              message: l10n.recipeLoadFailed,
              retryLabel: l10n.inventoryRetryAction,
              onRetry: () => ref
                ..invalidate(cookbookTemplatesProvider)
                ..invalidate(inventoryQuickEatItemsProvider),
            ),
            loading: () => const AppLoadingView(),
          ),
        ),
      ),
    );
  }

  Widget _body(IngredientCheckView check) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final steps = [
      if (check.found.isNotEmpty) _Step.found,
      if (check.missingCount > 0) _Step.missing,
      _Step.summary,
    ];
    final index = _step.clamp(0, steps.length - 1);
    final step = steps[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IngredientCheckTopBar(
          step: index + 1,
          steps: steps.length,
          backKey: IngredientCheckPage.backKey,
          onBack: _isBusy
              ? null
              : index == 0
              ? () => context.pop()
              : () => setState(() => _step = index - 1),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: switch (step) {
              _Step.found => IngredientCheckFoundList(
                check: check,
                onChoose: _choose,
                onPick: (line) => unawaited(_pick(line)),
              ),
              _Step.missing => IngredientCheckMissingList(
                check: check,
                onChoose: _choose,
                onHave: (line, {required rest}) =>
                    unawaited(_have(line, rest: rest)),
              ),
              _Step.summary => IngredientCheckSummary(check: check),
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: FilledButton(
              key: IngredientCheckPage.nextKey,
              onPressed: _isBusy
                  ? null
                  : step == _Step.summary
                  ? () => unawaited(_finish(check))
                  : () => setState(() => _step = index + 1),
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onAccent,
                minimumSize: const Size.fromHeight(AppGraphit.buttonHeight),
              ),
              child: Text(switch (step) {
                _Step.summary => l10n.recipeCheckFinish,
                _Step.found when check.missingCount > 0 =>
                  l10n.recipeCheckNextMissing(check.missingCount),
                _ => l10n.recipeCheckNext,
              }),
            ),
          ),
        ),
      ],
    );
  }

  void _choose(
    String ingredient,
    IngredientCheckChoice choice, {
    bool rest = false,
  }) => _controller.choose(ingredient, choice, rest: rest);

  Future<void> _pick(RecipeIngredientLine line) async {
    final pick = await showRecipeStockPicker(context: context, line: line);
    if (pick != null && mounted) {
      _controller.pick(line.ingredient, pick.itemId);
    }
  }

  /// Runs [action] while the check cannot close.
  Future<void> _whileBusy(Future<void> Function() action) async {
    if (_isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _have(RecipeIngredientLine line, {required bool rest}) {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final controller = _controller;
    return _whileBusy(() async {
      final filled = await PreparedMealPendingFoodFlow.fill(
        context: context,
        source: PreparedMealFoodSource.search,
        onFill: (itemId, _) async {
          controller.have(line.ingredient, itemId, rest: rest);
          return true;
        },
      );
      if (filled == false) {
        messenger.showAppSnackBar(
          l10n.recipeCheckHaveFailed,
          tone: AppSnackBarTone.error,
        );
      }
    });
  }

  Future<void> _finish(IngredientCheckView check) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final controller = _controller;
    var result = IngredientCheckFinish.busy;
    await _whileBusy(() async => result = await controller.finish(check));
    final failure = switch (result) {
      IngredientCheckFinish.recipeFailed => l10n.recipeCheckSaveFailed,
      IngredientCheckFinish.listFailed => l10n.recipeCheckListFailed,
      IngredientCheckFinish.done || IngredientCheckFinish.busy => null,
    };
    if (failure != null) {
      messenger.showAppSnackBar(failure, tone: AppSnackBarTone.error);
    } else if (result == IngredientCheckFinish.done && mounted) {
      context.pop();
    }
  }
}
