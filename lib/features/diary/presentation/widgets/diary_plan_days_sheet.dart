import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_plan_days_grid.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The days and the meal picked in the [showDiaryPlanDaysSheet].
typedef DiaryPlanDaysChoice = ({List<DateTime> days, MealType mealType});

/// Asks on which days [plan] is planned too: the days from today to the
/// last day that can be planned, and the meal, preset to the plan's.
/// Resolves with the choice, or null when the sheet closes.
Future<DiaryPlanDaysChoice?> showDiaryPlanDaysSheet({
  required BuildContext context,
  required CalorieEntry plan,
  required DateTime today,
}) {
  return showModalBottomSheet<DiaryPlanDaysChoice>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => DiaryPlanDaysSheet(plan: plan, today: today),
  );
}

/// The "Auch planen für" sheet: two weeks to pick days in, the meal, and
/// the button that plans them.
class DiaryPlanDaysSheet extends StatefulWidget {
  /// Creates the sheet for [plan].
  const new({required this.plan, required this.today, super.key});

  /// Key of the button that plans the picked days.
  static const confirmKey = Key('diary_plan_days_confirm');

  /// Key of the chip of [type].
  static Key mealKey(MealType type) => Key('diary_plan_days_meal_${type.name}');

  /// The plan to copy.
  final CalorieEntry plan;

  /// The current day.
  final DateTime today;

  @override
  State<DiaryPlanDaysSheet> createState() => _DiaryPlanDaysSheetState();
}

class _DiaryPlanDaysSheetState extends State<DiaryPlanDaysSheet> {
  final _days = <DateTime>{};
  late MealType _mealType = widget.plan.mealType;

  DateTime get _today => dateOnly(widget.today);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final kick = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    final kcal = widget.plan.totalKcal * _days.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xxs,
              children: [
                Text(l10n.diaryPlanCopyTitle.toUpperCase(), style: kick),
                Text(
                  widget.plan.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  l10n.eatPageKcal(widget.plan.totalKcal.round()),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            DiaryPlanDaysGrid(
              today: _today,
              selected: _days,
              onToggle: (day) => setState(
                () => _days.contains(day) ? _days.remove(day) : _days.add(day),
              ),
            ),
            Text(l10n.diaryPlanCopyMealLabel.toUpperCase(), style: kick),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final type in MealType.sectionOrder)
                  ChoiceChip(
                    key: DiaryPlanDaysSheet.mealKey(type),
                    label: Text(type.localizedName(l10n)),
                    selected: type == _mealType,
                    onSelected: (_) => setState(() => _mealType = type),
                  ),
              ],
            ),
            FilledButton(
              key: DiaryPlanDaysSheet.confirmKey,
              onPressed: _days.isEmpty
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pop((days: _days.toList()..sort(), mealType: _mealType)),
              child: Text(
                _days.isEmpty
                    ? l10n.diaryPlanCopyConfirm(0)
                    : l10n.diaryPlanCopyConfirmKcal(_days.length, kcal.round()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
