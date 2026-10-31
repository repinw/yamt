import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_after_plan_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_card_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_provider.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';

part 'diary_budget_card_data_provider.g.dart';

/// The budget card data of the normalized [day], or null while the balance
/// loads. The budget card and the dashboard tiles read it alike, so it is
/// built once per day.
@riverpod
DiaryBudgetCardData? diaryBudgetCardData(Ref ref, DateTime day) {
  final card = ref.watch(diaryBalanceCardProvider(day));
  if (card == null) return null;
  return DiaryBudgetCardData.from(
    card: card,
    today: ref.watch(diaryTodayProvider),
    nutrition: ref.watch(
      diaryDayDashboardControllerProvider(day)
          .select((s) => s.data?.nutritionBars),
    ),
    openPlans: ref.watch(diaryOpenPlansProvider(day)),
    paceShare: ref.watch(diaryPaceShareProvider(day)),
  );
}
