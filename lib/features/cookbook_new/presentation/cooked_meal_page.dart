import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/graphit_text_styles.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/cookbook_new/domain/cooked_pot.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cooked_meal_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooked_meal_pot_section.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooked_meal_summary.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/'
    'prepared_meal_detail_flow.dart';
import 'package:yamt/features/kitchen_utensils/application/'
    'kitchen_utensil_list_provider.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// How long the page waits for a meal that is missing from the stream. A
/// meal saved just now can reach the stream a moment after the page opens.
const _mealArrivalWait = Duration(seconds: 5);

/// "Gekocht": the cook sets the portions of a meal in the pot, picks the
/// pot, and may weigh it; "In Vorrat" marks the meal as cooked.
class CookedMealPage extends ConsumerStatefulWidget {
  /// Creates the page for the meal [mealId].
  const new({required this.mealId, super.key});

  /// Key of the "In Vorrat" button.
  static const saveKey = ValueKey<String>('cooked-save');

  /// The meal in the pot.
  final String mealId;

  @override
  ConsumerState<CookedMealPage> createState() => _CookedMealPageState();
}

class _CookedMealPageState extends ConsumerState<CookedMealPage> {
  final _grossController = TextEditingController();
  int? _portions;
  String? _utensilId;

  late final Timer _arrivalTimer;

  /// Whether a missing meal counts as gone instead of not arrived yet.
  var _waitedForMeal = false;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  Future<void> _save(
    PreparedMeal meal,
    int portions, {
    required int? tareWeight,
    required int? netWeight,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await ref
        .read(cookedMealControllerProvider(widget.mealId).notifier)
        .save(
          totalPortions: portions,
          potTareWeight: tareWeight,
          netWeight: netWeight,
        );
    if (!mounted) {
      return;
    }
    if (!saved) {
      messenger.showAppSnackBar(
        l10n.freeCookingSaveFailed,
        tone: AppSnackBarTone.error,
      );
      return;
    }
    context.pop();
    messenger.showAppSnackBar(l10n.cookedSaved(meal.name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final mealAsync = ref.watch(cookedMealProvider(widget.mealId));
    final isSaving = ref
        .watch(cookedMealControllerProvider(widget.mealId))
        .isLoading;

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            Expanded(
              child: mealAsync.when(
                data: (meal) => switch (meal) {
                  final meal? => _body(context, meal, isSaving: isSaving),
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
    );
  }

  Widget _header(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xxl,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => context.pop(),
            icon: Icon(Icons.close_rounded, color: colors.ink),
          ),
          Text(
            l10n.cookedKicker.toUpperCase(),
            style: context.graphitKickerStyle,
          ),
        ],
      ),
    );
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
    final utensil = utensilsAsync.value?.firstWhereOrNull(
      (item) => item.id == _utensilId,
    );
    final pot = CookedPot(
      grossInput: _grossController.text,
      tareWeight: utensil?.weightGrams ?? 0,
      portions: portions,
      totalKcal: meal.totalKcal,
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
                utensils: utensilsAsync.value ?? const <KitchenUtensil>[],
                utensilsFailed: utensilsAsync.hasError,
                utensilId: utensil?.id,
                onUtensilChanged: (id) => setState(() => _utensilId = id),
                grossController: _grossController,
                result: switch (pot.netWeight) {
                  final grams? => l10n.cookedNetWeight(grams),
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
                null => l10n.cookedPerPortion(pot.kcalPerPortion),
              }, style: textTheme.bodyMedium?.copyWith(color: colors.muted)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: FilledButton(
            key: CookedMealPage.saveKey,
            onPressed: isSaving || pot.isTooLight
                ? null
                : () => unawaited(
                    _save(
                      meal,
                      portions,
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
