import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/device/screen_wake_lock.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/cookbook_new/domain/combined_meal.dart';
import 'package:yamt/features/cookbook_new/domain/cooked_pot.dart';
import 'package:yamt/features/cookbook_new/presentation/combined_meal_discard_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cooked_meal_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/cooked_meal_save_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooked_meal_cookbook_switch.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooked_meal_header.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooked_meal_pot_section.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooked_meal_summary.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/'
    'prepared_meal_detail_flow.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_gone_flow.dart';
import 'package:yamt/features/kitchen_utensils/application/'
    'kitchen_utensil_list_provider.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// How long the page waits for a meal that is missing from the stream. A
/// meal saved just now can reach the stream a moment after the page opens.
const _mealArrivalWait = Duration(seconds: 5);

/// "Gekocht": the cook sets the portions of a meal in the pot, picks the
/// pot, and may weigh it. Saving marks the meal as cooked and keeps it in
/// the Vorrat; the "Ins Kochbuch" switch also saves it as a template.
class CookedMealPage extends ConsumerStatefulWidget {
  /// Creates the page for the meal [mealId].
  const new({required this.mealId, super.key});

  /// Key of the save button.
  static const saveKey = ValueKey<String>('cooked-save');

  /// The meal in the pot.
  final String mealId;

  @override
  ConsumerState<CookedMealPage> createState() => _CookedMealPageState();
}

class _CookedMealPageState extends ConsumerState<CookedMealPage> {
  final _grossController = TextEditingController();
  int? _portions;
  var _inPieces = false;

  /// Whether the cook weighs a combined meal instead of trusting the sum of
  /// its ingredients.
  var _weighs = false;
  String? _utensilId;
  var _toCookbook = false;

  late final Timer _arrivalTimer;
  late final ScreenWakeLock _wakeLock;

  /// Whether a missing meal counts as not found instead of not arrived yet.
  var _waitedForMeal = false;

  /// Whether the cook discards a combined meal, so its leaving the Vorrat
  /// does not count as gone.
  var _discarding = false;

  @override
  void initState() {
    super.initState();
    _wakeLock = ref.read(screenWakeLockProvider)..acquire();
    _grossController.addListener(() => setState(() {}));
    _arrivalTimer = Timer(
      _mealArrivalWait,
      () => setState(() => _waitedForMeal = true),
    );
  }

  @override
  void dispose() {
    _arrivalTimer.cancel();
    _grossController.dispose();
    _wakeLock.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    if (!_discarding) {
      PreparedMealGoneFlow.closeWhenGone(ref, context, widget.mealId);
    }
    final mealAsync = ref.watch(livePreparedMealProvider(widget.mealId));
    // A combined meal is not cooked yet: leaving it gives its foods back.
    final isCombined = switch (mealAsync.value) {
      final meal? => meal.isCombined,
      null => false,
    };
    final isSaving = ref
        .watch(cookedMealControllerProvider(widget.mealId))
        .isLoading;
    // A meal on its way may be a combined one, so the page waits for it,
    // unless it never arrives.
    final isWaiting =
        mealAsync.value == null && !_waitedForMeal && !mealAsync.hasError;
    final mayClose = !isCombined && !isWaiting;
    final mayDiscard = isCombined && !isSaving && !_discarding;

    return PopScope(
      canPop: mayClose,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && mayDiscard) {
          unawaited(_discard());
        }
      },
      child: Scaffold(
        backgroundColor: colors.paper,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CookedMealHeader(
                kicker: isCombined
                    ? l10n.cookedCombinedKicker
                    : l10n.cookedKicker,
                onClose: mayClose
                    ? context.pop
                    : mayDiscard
                    ? () => unawaited(_discard())
                    : null,
              ),
              Expanded(
                child: mealAsync.when(
                  data: (meal) => switch (meal) {
                    final meal? => _body(context, meal, isSaving: isSaving),
                    // A meal saved just now may still be on its way. A meal
                    // that was here and is gone closes the page instead.
                    null when _waitedForMeal => Center(
                      child: Text(l10n.cookedLoadFailed),
                    ),
                    null => const AppLoadingView(),
                  },
                  loading: () => const AppLoadingView(),
                  error: (_, _) => Center(child: Text(l10n.cookedLoadFailed)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Discards the combined meal and closes the page.
  Future<void> _discard() async {
    final gone = await CombinedMealDiscardFlow.discard(
      context: context,
      ref: ref,
      mealId: widget.mealId,
      onConfirmed: () => setState(() => _discarding = true),
    );
    if (!mounted) {
      return;
    }
    if (gone) {
      context.pop();
    } else if (_discarding) {
      setState(() => _discarding = false);
    }
  }

  Widget _body(
    BuildContext context,
    PreparedMeal meal, {
    required bool isSaving,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final portions = _portions ?? meal.totalPortions;
    final utensilsAsync = ref.watch(kitchenUtensilListProvider);
    final utensils = utensilsAsync.value ?? const <KitchenUtensil>[];
    final utensil = utensils.firstWhereOrNull((item) => item.id == _utensilId);
    final ingredientsWeight = meal.isCombined && !_weighs
        ? meal.ingredientsGrams
        : null;
    final pot = CookedPot(
      // The section hides the scale for pieces and without a pot to pick.
      grossInput: _inPieces || utensilsAsync.hasError || utensils.isEmpty
          ? ''
          : _grossController.text,
      tareWeight: utensil?.weightGrams,
      portions: portions,
      totalKcal: meal.totalKcal,
      ingredientsWeight: _inPieces ? null : ingredientsWeight,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            children: [
              CookedMealSummary(
                meal: meal,
                onFill: () => unawaited(
                  PreparedMealDetailFlow.open(
                    context: context,
                    ref: ref,
                    meal: meal,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              CookedMealPotSection(
                portions: portions,
                onPortionsChanged: (value) => setState(() => _portions = value),
                inPieces: _inPieces,
                onInPiecesChanged: (value) => setState(() => _inPieces = value),
                ingredientsWeight: ingredientsWeight,
                onWeigh: () => setState(() => _weighs = true),
                utensils: utensils,
                utensilsFailed: utensilsAsync.hasError,
                utensilId: utensil?.id,
                onUtensilChanged: (id) => setState(() => _utensilId = id),
                grossController: _grossController,
                result: switch (pot.netWeight) {
                  final grams? => l10n.cookedNetWeight(grams),
                  null when pot.needsUtensil => l10n.cookedNeedsUtensil,
                  null when pot.isTooLight => l10n.cookedTooLight,
                  null => '',
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(switch (pot.gramsPerPortion) {
                final grams? => l10n.cookedPerPortionWeighed(
                  grams,
                  pot.kcalPerPortion,
                ),
                null when _inPieces => l10n.cookedPerPiece(pot.kcalPerPortion),
                null => l10n.cookedPerPortion(pot.kcalPerPortion),
              }, style: textTheme.bodyMedium?.copyWith(color: colors.muted)),
              const SizedBox(height: AppSpacing.xxl),
              CookedMealCookbookSwitch(
                value: _toCookbook,
                onChanged: (value) => setState(() => _toCookbook = value),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: FilledButton(
            key: CookedMealPage.saveKey,
            onPressed: isSaving || pot.needsUtensil || pot.isTooLight
                ? null
                : () => unawaited(
                    CookedMealSaveFlow.save(
                      context: context,
                      ref: ref,
                      meal: meal,
                      portions: portions,
                      servedInPieces: _inPieces,
                      toCookbook: _toCookbook,
                      tareWeight: utensil?.weightGrams,
                      netWeight: pot.netWeight,
                    ),
                  ),
            style: FilledButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              minimumSize: const Size.fromHeight(AppGraphit.buttonHeight),
            ),
            child: Text(l10n.cookedSave),
          ),
        ),
      ],
    );
  }
}
