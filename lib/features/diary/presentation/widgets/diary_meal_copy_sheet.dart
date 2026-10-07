import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/core/widgets/app_selection_list_tiles.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_plan_days_grid.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The days picked in the [showDiaryMealCopySheet] and the foods to plan
/// on each.
typedef DiaryMealCopyChoice = ({
  List<DateTime> days,
  List<CalorieEntry> entries,
});

/// Asks which meals of [day] to copy as plans, preset to [mealType], and on
/// which days. [entries] are the eaten foods and plans of [day]. Resolves
/// with the choice, or null when the sheet closes.
Future<DiaryMealCopyChoice?> showDiaryMealCopySheet({
  required BuildContext context,
  required DateTime day,
  required MealType mealType,
  required List<CalorieEntry> entries,
  required DateTime today,
}) {
  return showModalBottomSheet<DiaryMealCopyChoice>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => DiaryMealCopySheet(
      day: day,
      mealType: mealType,
      entries: entries,
      today: today,
    ),
  );
}

/// The "Als Plan kopieren" sheet: the meals of a day to tick, the two weeks
/// to pick days in, and the button that plans them.
class DiaryMealCopySheet extends StatefulWidget {
  /// Creates the sheet.
  const new({
    required this.day,
    required this.mealType,
    required this.entries,
    required this.today,
    super.key,
  });

  /// Key of the button that plans the picked days.
  static const confirmKey = Key('diary_meal_copy_confirm');

  /// Key of the check box of [type].
  static Key mealKey(MealType type) => Key('diary_meal_copy_${type.name}');

  /// The day to copy from.
  final DateTime day;

  /// The meal ticked at first.
  final MealType mealType;

  /// The eaten foods and plans of [day].
  final List<CalorieEntry> entries;

  /// The current day.
  final DateTime today;

  @override
  State<DiaryMealCopySheet> createState() => _DiaryMealCopySheetState();
}

class _DiaryMealCopySheetState extends State<DiaryMealCopySheet> {
  final _days = <DateTime>{};
  late final Set<MealType> _meals = {widget.mealType};

  List<CalorieEntry> get _picked => [
    for (final entry in widget.entries)
      if (_meals.contains(entry.mealType)) entry,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final kick = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    final picked = _picked;
    final kcal =
        picked.fold<double>(0, (sum, entry) => sum + entry.totalKcal) *
        _days.length;
    final canConfirm = _days.isNotEmpty && picked.isNotEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xxs,
              children: [
                Text(l10n.diaryMealCopyAction.toUpperCase(), style: kick),
                Text(
                  DateFormat.MMMMEEEEd(localeName).format(widget.day),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                for (final type in MealType.sectionOrder) ?_mealRow(type, l10n),
              ],
            ),
            Text(l10n.diaryMealCopyDaysLabel.toUpperCase(), style: kick),
            DiaryPlanDaysGrid(
              today: dateOnly(widget.today),
              selected: _days,
              onToggle: (day) => setState(
                () => _days.contains(day) ? _days.remove(day) : _days.add(day),
              ),
            ),
            FilledButton(
              key: DiaryMealCopySheet.confirmKey,
              onPressed: canConfirm
                  ? () => Navigator.of(context)
                        .pop((days: _days.toList()..sort(), entries: picked))
                  : null,
              child: Text(
                _days.isEmpty
                    ? l10n.diaryPlanCopyConfirm(0)
                    : picked.isEmpty
                    ? l10n.diaryMealCopyPickMeal
                    : l10n.diaryPlanCopyConfirmKcal(_days.length, kcal.round()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The check box row of the meal [type], or null when [type] has no food.
  Widget? _mealRow(MealType type, AppLocalizations l10n) {
    final entries = [
      for (final entry in widget.entries)
        if (entry.mealType == type) entry,
    ];
    if (entries.isEmpty) {
      return null;
    }
    final kcal = entries.fold<double>(0, (sum, entry) => sum + entry.totalKcal);
    return AppCheckboxListTile(
      key: DiaryMealCopySheet.mealKey(type),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: _meals.contains(type),
      onChanged: (checked) => setState(
        () => checked ?? false ? _meals.add(type) : _meals.remove(type),
      ),
      title: Text(type.localizedName(l10n)),
      secondary: Text(l10n.eatPageKcal(kcal.round())),
    );
  }
}
