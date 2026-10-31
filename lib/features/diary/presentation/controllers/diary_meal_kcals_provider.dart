import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_after_plan_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/models/diary_meal_kcal.dart';

part 'diary_meal_kcals_provider.g.dart';

/// The kcal of each meal of the normalized [day], as the meal headings
/// below the dashboard count them: eaten, plus the plans the heading
/// counts on top. Null while the day loads.
@riverpod
List<DiaryMealKcal>? diaryMealKcals(Ref ref, DateTime day) {
  final sections = ref.watch(
    diaryDayDashboardControllerProvider(day)
        .select((state) => state.data?.mealSections),
  );
  if (sections == null) return null;
  final withOpenPlans = ref.watch(
    diaryOpenPlansProvider(day).select((plans) => plans?.counted ?? false),
  );
  return diaryMealKcalsOf(sections, withOpenPlans: withOpenPlans);
}

/// The kcal of each of [sections] as its meal heading counts them, the
/// open plans included when [withOpenPlans].
List<DiaryMealKcal> diaryMealKcalsOf(
  List<DiaryMealSection> sections, {
  required bool withOpenPlans,
}) => [
  for (final section in sections)
    _mealKcal(section, withOpenPlans: withOpenPlans),
];

DiaryMealKcal _mealKcal(
  DiaryMealSection section, {
  required bool withOpenPlans,
}) {
  final eaten = section.entries.fold<double>(
    0,
    (sum, entry) => sum + entry.totalKcal,
  );
  final total = section.headingTotal(withOpenPlans: withOpenPlans).kcal;
  return DiaryMealKcal(
    mealType: section.mealType,
    eaten: eaten,
    planned: total > eaten ? total - eaten : 0,
  );
}
