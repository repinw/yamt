import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/hero_tags.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/widgets/nutrition_facts_rows.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meal_eat_sheet_controller.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/models/prepared_meal_actions.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_gone_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_amount_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_components_list.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_label_table.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_meal_detail_sections.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_header.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_text_field.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_when_menu.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Eat page content for a prepared meal.
class PreparedMealEatSheetBody extends ConsumerStatefulWidget {
  /// Creates the prepared meal eat page content.
  const new({
    required this.meal,
    required this.localeName,
    this.initialLoggedAt,
    this.initialMealType,
    this.actions,
    super.key,
  });

  /// Meal to eat.
  final PreparedMeal meal;

  /// Locale the amounts are formatted in.
  final String localeName;

  /// Preselected log time.
  final DateTime? initialLoggedAt;

  /// Preselected meal.
  final MealType? initialMealType;

  /// Meal actions of the Vorrat. With them the page is the meal's detail
  /// page: it lists the ingredients and offers edit, unbundle and throw
  /// away.
  final PreparedMealActions? actions;

  @override
  ConsumerState<PreparedMealEatSheetBody> createState() =>
      _PreparedMealEatSheetBodyState();
}

class _PreparedMealEatSheetBodyState
    extends ConsumerState<PreparedMealEatSheetBody> {
  late final PreparedMealEatSheetControllerProvider _provider =
      preparedMealEatSheetControllerProvider(
        meal: widget.meal,
        localeName: widget.localeName,
        initialLoggedAt: widget.initialLoggedAt,
        initialMealType: widget.initialMealType,
      );
  final _amount = EatSheetTextField();

  PreparedMealEatSheetController get _controller =>
      ref.read(_provider.notifier);

  @override
  void initState() {
    super.initState();
    _syncText(ref.read(_provider));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(_provider, (_, next) => _syncText(next));
    PreparedMealGoneFlow.closeWhenGone(ref, context, widget.meal.id);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(_provider);
    // The meal the page shows and logs.
    final meal = state.calculator.meal;
    // The entered portions start from the opened copy, so a meal that was in
    // the pot when the page opened waits for "Gekocht" and a reopen.
    final isInPot = widget.meal.isInPot || meal.isInPot;
    // A meal plans once every row is filled or ignored, also from the pot;
    // eating it waits for "Gekocht". A pot cooked while the page is open
    // waits for a reopen, as the entered share would turn into portions.
    final canPlan =
        meal.allows(PreparedMealAction.plan) &&
        widget.meal.isInPot == meal.isInPot;
    final canEat = !isInPot && meal.allows(PreparedMealAction.eat);
    final nutrition = state.nutrition;
    final imageRef = maybeLocalImageAssetRef(meal.imageAssetId);
    final imageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;

    return EatPageScaffold(
      whenControl: EatWhenMenu(
        loggedAt: state.loggedAt,
        today: state.today,
        mealType: state.mealType,
        onDayPicked: _controller.setLoggedDay,
        onMealTypeChanged: _controller.setMealType,
        allowsPlanDays: canPlan,
      ),
      isPlan: state.isPlan,
      kcal: nutrition?.eaten.kcal,
      confirmButtonKey: const Key('prepared_meal_eat_confirm_button'),
      // A meal in the pot can only be planned, a share of the pot.
      onConfirm: canEat || (canPlan && state.isPlan) ? _submit : null,
      onPlan: canPlan ? _plan : null,
      cancelButtonKey: const Key('prepared_meal_eat_cancel_button'),
      children: [
        EatPageHeader(
          title: meal.name,
          caption: isInPot
              ? l10n.inventoryMealInPot
              : meal.hasPendingRecipeIngredients
              ? l10n.cookedOpenRows(meal.pendingRecipeIngredients.length)
              : l10n.eatPageInStock(state.stockLabel(l10n)),
          imageUrl: meal.imageUrl,
          imageBytes: imageBytes,
          collageImageUrls: [
            for (final component in meal.components) component.imageUrl,
          ],
          imageKey: const Key('prepared_meal_eat_sheet_hero_cover'),
          heroTag: HeroTags.preparedMealImage(meal.id),
          fallbackLetter: inventoryPictureLetter(meal.name),
        ),
        if (nutrition != null)
          EatLabelTable(
            key: const Key('prepared_meal_nutrition_table'),
            rows: nutritionFactsRows(context, eaten: nutrition.eaten),
            eatenHeader: state.portionsHeader(l10n),
          ),
        EatAmountRuler(
          controller: _amount.controller,
          focusNode: _amount.focusNode,
          unitLabel: state.amountUnit(l10n),
          value: state.amountValue,
          max: state.amountMax,
          step: state.amountStep,
          marks: [
            for (final (index, value) in state.quickValues.indexed)
              EatRulerMark(
                label: state.markLabel(l10n, index, value),
                value: value.toDouble(),
                isSelected: state.amount == value,
                onPressed: () => _controller.pickAmount(value),
              ),
          ],
          allowFractionalInput: true,
          hint: state.amountHint(l10n),
          errorText: state.hasAmountError
              ? l10n.preparedMealInvalidPortionsRange
              : null,
          onTextChanged: (text) => _controller.setAmountText(text),
          onSliderChanged: (value) => _controller.pickAmount(value),
          onUnitPressed: state.calculator.canUseGrams
              ? () => _controller.switchMode()
              : null,
        ),
        if (widget.actions case final actions?)
          EatMealDetailSections(meal: meal, actions: actions)
        else if (state.components.isNotEmpty)
          EatComponentsList(
            components: [
              for (final (:component, :amount) in state.components)
                (
                  name: component.name,
                  amount: eatComponentAmount(l10n, amount, component.usedUnit),
                  kcal: null,
                ),
            ],
          ),
      ],
    );
  }

  void _syncText(PreparedMealEatSheetState state) {
    _amount.sync(state.amountText);
  }

  Future<void> _plan() async {
    final state = ref.read(_provider);
    final day = await showEatPlanDayPicker(
      context,
      today: state.today,
      loggedAt: state.loggedAt,
    );
    if (day == null || !mounted) return;
    _controller.setLoggedDay(day);
    _submit(asPlan: true);
  }

  void _submit({bool asPlan = false}) {
    final request = _controller.submit(asPlan: asPlan);
    if (request == null) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(request);
  }
}
