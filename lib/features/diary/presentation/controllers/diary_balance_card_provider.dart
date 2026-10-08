import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_day_dashboard_controller.dart';

part 'diary_balance_card_provider.g.dart';

/// The resolved balance of [day], read by the balance card, the macro strip
/// and the home widget, so all three show the same numbers and move to the
/// new day together. `null` while the day's dashboard has not loaded yet.
///
/// Lives in `presentation/` because it derives from the dashboard
/// controller's state.
@riverpod
DiaryBalanceCardData? diaryBalanceCard(Ref ref, DateTime day) {
  final data = ref.watch(
    diaryDayDashboardControllerProvider(day).select((s) => s.data),
  );
  if (data == null) {
    return null;
  }
  return DiaryBalanceSource.fromDashboardData(data)
      .resolve(now: ref.watch(diaryTodayProvider));
}
