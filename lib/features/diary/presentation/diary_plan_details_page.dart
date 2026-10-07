import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_entry_details_state.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_plan_details_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_entry_label_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_action_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_amount_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_components_list.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_meal_portions_row.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_text_field.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_when_menu.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What the user chose on the plan details page.
sealed class DiaryPlanDetailsAction {
  const new();
}

/// Eat the plan as planned.
final class DiaryPlanAccept extends DiaryPlanDetailsAction {
  /// Creates the action.
  const new();
}

/// Remove the plan.
final class DiaryPlanRemove extends DiaryPlanDetailsAction {
  /// Creates the action.
  const new();
}

/// Plan the food on more days.
final class DiaryPlanCopy extends DiaryPlanDetailsAction {
  /// Creates the action.
  const new();
}

/// Save the plan with another day, meal, amount or number of portions.
final class DiaryPlanChange extends DiaryPlanDetailsAction {
  /// Creates the action for the changed [plan].
  const new(this.plan);

  /// The plan with its new day, meal, amount or portions.
  final CalorieEntry plan;
}

/// Details of a plan, in the food label look of the entry details.
///
/// The day and meal can change; the main button then saves the plan.
/// Pops with the chosen [DiaryPlanDetailsAction], or null on close. The
/// caller runs it, so its snack bar shows on the diary.
class DiaryPlanDetailsPage extends ConsumerStatefulWidget {
  /// Creates the page for [plan].
  const new({
    required this.plan,
    required this.canAccept,
    required this.today,
    super.key,
  });

  /// Key of the button that eats or saves the plan.
  static const acceptButtonKey = Key('diary_plan_details_accept_button');

  /// Key of the line that removes the plan.
  static const removeKey = Key('diary_plan_details_remove');

  /// Key of the line that plans the food on more days.
  static const copyKey = Key('diary_plan_details_copy');

  /// Key of the amount ruler.
  static const amountKey = Key('diary_plan_details_amount');

  /// Key of the close button.
  static const closeButtonKey = Key('diary_plan_details_close_button');

  /// The plan.
  final CalorieEntry plan;

  /// Whether the plan's day has come, so it can be eaten.
  final bool canAccept;

  /// The current day, for the day menu.
  final DateTime today;

  @override
  ConsumerState<DiaryPlanDetailsPage> createState() =>
      _DiaryPlanDetailsPageState();
}

class _DiaryPlanDetailsPageState extends ConsumerState<DiaryPlanDetailsPage> {
  final _amount = EatSheetTextField();

  late final DiaryPlanDetailsControllerProvider _provider =
      diaryPlanDetailsControllerProvider(
        widget.plan.id,
        normalizeLocalDay(widget.plan.loggedAt),
        widget.today,
      );

  @override
  void initState() {
    super.initState();
    _amount.sync(diaryEntryAmountText(widget.plan.consumedAmount));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // A plan eaten or removed elsewhere closes its page.
    ref.listen(_provider, (previous, next) {
      // An amount that follows the plan shows in the field too.
      final text = next?.amount.amountText;
      if (text != null && text != _amount.controller.text) {
        _amount.sync(text);
      }
      // The page may be closing already, after its own action removed it.
      if (previous != null &&
          next == null &&
          (ModalRoute.of(context)?.isCurrent ?? false)) {
        Navigator.of(context).pop();
      }
    });
    final state = ref.watch(_provider);
    if (state == null) {
      // Closed above when it went away; a route on top kept it open.
      return Scaffold(appBar: AppBar());
    }
    final controller = ref.read(_provider.notifier);
    final amountState = state.amount;
    final preview = state.preview;
    final isChanged = state.isChanged;
    void pop(DiaryPlanDetailsAction action) =>
        Navigator.of(context).pop(action);
    return EatPageScaffold(
      whenControl: EatWhenMenu(
        loggedAt: state.loggedAt,
        today: widget.today,
        mealType: state.mealType,
        onlyPlanDays: true,
        onMealTypeChanged: controller.setMealType,
        onDayPicked: controller.setDay,
      ),
      kcal: preview.totalKcal,
      confirmLabel: isChanged
          ? l10n.diaryPlanSaveAction
          : l10n.diaryPlanAcceptAction,
      confirmButtonKey: DiaryPlanDetailsPage.acceptButtonKey,
      onConfirm: amountState.hasAmountError
          ? null
          : isChanged
          ? () => pop(DiaryPlanChange(state.changed))
          : widget.canAccept
          ? () => pop(const DiaryPlanAccept())
          : null,
      confirmHint: isChanged || widget.canAccept
          ? null
          : l10n.diaryPlanAcceptLaterHint,
      cancelButtonKey: DiaryPlanDetailsPage.closeButtonKey,
      children: [
        DiaryEntryLabelSection(entry: preview),
        if (amountState.canEditAmount)
          EatAmountRuler(
            key: DiaryPlanDetailsPage.amountKey,
            controller: _amount.controller,
            focusNode: _amount.focusNode,
            unitLabel: consumedUnitSymbol(l10n, widget.plan.consumedUnit),
            value: amountState.rulerValue,
            max: amountState.rulerMax,
            step: amountState.rulerStep,
            marks: const [],
            allowFractionalInput: true,
            errorText: amountState.hasAmountError
                ? l10n.caloriesPositiveNumberValidation
                : null,
            onTextChanged: controller.setAmountText,
            onSliderChanged: (amount) {
              final text = diaryEntryAmountText(amount);
              _amount.sync(text);
              controller.setAmountText(text);
            },
          ),
        if (state.portions case final portions?)
          EatMealPortionsRow(
            portions: portions,
            max: state.maxPortions,
            onChanged: controller.setPortions,
          ),
        if (preview.isBundle)
          EatComponentsList(
            initiallyExpanded: true,
            components: [
              for (final food in preview.bundleComponents)
                (
                  name: food.name,
                  amount: food.amountLabel,
                  kcal: food.totalKcal,
                ),
            ],
          ),
        EatActionCard(
          title: l10n.diaryPlanSemanticsLabel,
          actions: [
            (
              key: DiaryPlanDetailsPage.copyKey,
              icon: Icons.event_repeat_rounded,
              label: l10n.diaryPlanCopyAction,
              color: FoodLabelColors.of(context).ink,
              onPressed: () => pop(const DiaryPlanCopy()),
            ),
            (
              key: DiaryPlanDetailsPage.removeKey,
              icon: Icons.event_busy_rounded,
              label: l10n.diaryPlanRemoveAction,
              color: Theme.of(context).colorScheme.error,
              onPressed: () => pop(const DiaryPlanRemove()),
            ),
          ],
        ),
      ],
    );
  }
}
