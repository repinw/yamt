import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/diary/application/diary_open_plans.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';

part 'diary_after_plan_controller.g.dart';

const _afterPlanKey = 'diary_after_plan_v1';
const _afterPlanOffValue = 'off';

/// Whether the head counts the open plans of today, so it shows what is
/// left after them ("Nach Plan"). On by default; the choice is saved on the
/// device.
@riverpod
class DiaryAfterPlanController extends _$DiaryAfterPlanController {
  @override
  bool build() {
    final preferences = ref.watch(appPreferencesProvider);
    return preferences.getStringSync(_afterPlanKey) != _afterPlanOffValue;
  }

  /// Switches between counting the plans and leaving them out.
  Future<void> toggle() async {
    final counted = !state;
    state = counted;
    final preferences = ref.read(appPreferencesProvider);
    if (counted) {
      await preferences.remove(_afterPlanKey);
    } else {
      await preferences.setString(_afterPlanKey, _afterPlanOffValue);
    }
  }
}

/// The open plans of [day], counted when the user counts them; null when the
/// day offers none.
@riverpod
DiaryOpenPlans? diaryOpenPlans(Ref ref, DateTime day) {
  final data = ref.watch(diaryDayDashboardControllerProvider(day)).data;
  if (data == null) return null;
  return DiaryOpenPlans.of(
    data,
    today: ref.watch(clockProvider)(),
    counted: ref.watch(diaryAfterPlanControllerProvider),
  );
}
