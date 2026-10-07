import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_entry_label_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_action_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_components_list.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
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

/// Save the plan with another day or meal.
final class DiaryPlanChange extends DiaryPlanDetailsAction {
  /// Creates the action for the changed [plan].
  const new(this.plan);

  /// The plan with its new day and meal.
  final CalorieEntry plan;
}

/// Details of a plan, in the food label look of the entry details.
///
/// The day and meal can change; the main button then saves the plan.
/// Pops with the chosen [DiaryPlanDetailsAction], or null on close. The
/// caller runs it, so its snack bar shows on the diary.
class DiaryPlanDetailsPage extends StatefulWidget {
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

  /// Key of the close button.
  static const closeButtonKey = Key('diary_plan_details_close_button');

  /// The plan.
  final CalorieEntry plan;

  /// Whether the plan's day has come, so it can be eaten.
  final bool canAccept;

  /// The current day, for the day menu.
  final DateTime today;

  @override
  State<DiaryPlanDetailsPage> createState() => _DiaryPlanDetailsPageState();
}

class _DiaryPlanDetailsPageState extends State<DiaryPlanDetailsPage> {
  late DateTime _loggedAt = widget.plan.loggedAt;
  late MealType _mealType = widget.plan.mealType;

  bool get _isChanged =>
      _loggedAt != widget.plan.loggedAt || _mealType != widget.plan.mealType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plan = widget.plan;
    void pop(DiaryPlanDetailsAction action) =>
        Navigator.of(context).pop(action);
    return EatPageScaffold(
      whenControl: EatWhenMenu(
        loggedAt: _loggedAt,
        today: widget.today,
        mealType: _mealType,
        onlyPlanDays: true,
        onMealTypeChanged: (type) => setState(() => _mealType = type),
        // The plan keeps its time of day.
        onDayPicked: (day) => setState(
          () => _loggedAt = DateTime(
            day.year,
            day.month,
            day.day,
            _loggedAt.hour,
            _loggedAt.minute,
          ),
        ),
      ),
      kcal: plan.totalKcal,
      confirmLabel: _isChanged
          ? l10n.diaryPlanSaveAction
          : l10n.diaryPlanAcceptAction,
      confirmButtonKey: DiaryPlanDetailsPage.acceptButtonKey,
      onConfirm: _isChanged
          ? () => pop(
              DiaryPlanChange(
                plan.copyWith(loggedAt: _loggedAt, mealType: _mealType),
              ),
            )
          : widget.canAccept
          ? () => pop(const DiaryPlanAccept())
          : null,
      confirmHint: _isChanged || widget.canAccept
          ? null
          : l10n.diaryPlanAcceptLaterHint,
      cancelButtonKey: DiaryPlanDetailsPage.closeButtonKey,
      children: [
        DiaryEntryLabelSection(entry: plan),
        if (plan.isBundle)
          EatComponentsList(
            initiallyExpanded: true,
            components: [
              for (final food in plan.bundleComponents)
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
