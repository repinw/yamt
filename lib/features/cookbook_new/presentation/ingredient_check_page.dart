import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/ingredient_check_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/ingredient_check_draft.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/ingredient_check_view.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_edit_list.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_found_list.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_missing_list.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_summary.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_title.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_top_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_bottom_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_stock_picker_sheet.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/presentation/models/prepared_meal_food_source.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_pending_food_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum _Step { question, edit, found, missing, summary }

/// "Zutaten prüfen" for a recipe: the ingredients the Vorrat holds, the ones
/// it lacks, and a summary. "Fertig" puts the chosen ones on the shopping
/// list, saves the Vorrat items and ignored ingredients on the recipe, and
/// goes back to the recipe page. Closing the check changes nothing.
class IngredientCheckPage extends ConsumerStatefulWidget {
  /// Creates the check of the recipe [recipeId].
  const new({required this.recipeId, super.key});

  /// Key of the button at the bottom: "Weiter", or "Fertig" at the end.
  static const nextKey = ValueKey<String>('ingredient-check-next');

  /// Key of "Ja" on the question whether to change something.
  static const changeKey = ValueKey<String>('ingredient-check-change');

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
  var _wantsChanges = false;
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
    final view = check.view;
    final steps = [
      _Step.question,
      if (_wantsChanges) _Step.edit,
      if (check.found.isNotEmpty) _Step.found,
      if (check.missingCount > 0) _Step.missing,
      _Step.summary,
    ];
    final index = _step.clamp(0, steps.length - 1);
    final step = steps[index];
    // A field that loses focus hands its value over before the step goes.
    void go(int step) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _step = step);
    }

    void next({bool? wantsChanges}) {
      if (wantsChanges == false) {
        _controller.discardEdits();
      }
      _wantsChanges = wantsChanges ?? _wantsChanges;
      go(index + 1);
    }

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
              : () => go(index - 1),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: switch (step) {
              _Step.question => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxl),
                child: IngredientCheckTitle(
                  kicker: l10n.recipeCheckChangeKicker(
                    view.recipe.name,
                    view.portions,
                  ),
                  title: l10n.recipeCheckChangeTitle,
                  hint: l10n.recipeCheckChangeHint,
                ),
              ),
              _Step.edit => IngredientCheckEditList(
                check: check,
                onAmount: (line, amount) =>
                    _controller.setAmount(view, line, amount),
                onRemove: (line) => _controller.remove(view, line),
                onAdd: (text) => _controller.add(view, text),
              ),
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
              _Step.summary => IngredientCheckSummary(
                check: check,
                onSaveEdits: (save) => _controller.setSaveEdits(save: save),
              ),
            },
          ),
        ),
        RecipeBottomBar(
          buttonKey: IngredientCheckPage.nextKey,
          label: switch (step) {
            _Step.question => l10n.recipeCheckChangeNo,
            _Step.summary => l10n.recipeCheckFinish,
            _Step.found when check.missingCount > 0 =>
              l10n.recipeCheckNextMissing(check.missingCount),
            _ => l10n.recipeCheckNext,
          },
          onPressed: _isBusy
              ? null
              : switch (step) {
                  _Step.question => () => next(wantsChanges: false),
                  _Step.summary => () => unawaited(_finish(check)),
                  _ => next,
                },
          secondaryKey: IngredientCheckPage.changeKey,
          secondaryLabel: step == _Step.question
              ? l10n.recipeCheckChangeYes
              : null,
          onSecondary: () => next(wantsChanges: true),
        ),
      ],
    );
  }

  void _choose(String key, IngredientCheckChoice choice, {bool rest = false}) =>
      _controller.choose(key, choice, rest: rest);

  Future<void> _pick(RecipeIngredientLine line) async {
    final pick = await showRecipeStockPicker(context: context, line: line);
    if (pick != null && mounted) {
      _controller.pick(line.key, pick.itemId);
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
          controller.have(line.key, itemId, rest: rest);
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
    }
    // The recipe holds the choices once only the list failed.
    if (result
        case IngredientCheckFinish.done || IngredientCheckFinish.listFailed
        when mounted) {
      context.pop();
    }
  }
}
