import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/diary/application/diary_open_plans.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_card_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';

part 'diary_after_plan_controller.g.dart';

/// Whether the head counts the open plans of today, so it shows what is
/// left after them ("Nach Plan"). On whenever the diary opens; turning it
/// off is not saved.
@riverpod
class DiaryAfterPlanController extends _$DiaryAfterPlanController {
  @override
  bool build() => true;

  /// Switches between counting the plans and leaving them out.
  void toggle() => state = !state;
}

/// The open plans of [day], counted when the user counts them; null when the
/// day offers none. A practice day and a scheduled restart have no "Nach
/// Plan" chip, so they offer none either: the budget card and the meal
/// headings both follow this one answer.
@riverpod
DiaryOpenPlans? diaryOpenPlans(Ref ref, DateTime day) {
  final data = ref.watch(diaryDayDashboardControllerProvider(day)).data;
  if (data == null) return null;
  final card = ref.watch(diaryBalanceCardProvider(day));
  if (card?.practiceDay != null || card?.scheduledRestart != null) {
    return null;
  }
  return DiaryOpenPlans.of(
    data,
    today: ref.watch(clockProvider)(),
    counted: ref.watch(diaryAfterPlanControllerProvider),
  );
}
