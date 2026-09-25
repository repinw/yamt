import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

part 'diary_weekly_checkin_success_dismissal_controller.g.dart';

const _dismissedKey = 'diary_weekly_checkin_success_dismissed_v1';

/// Day key of the weekly check-in whose success message the user closed, so
/// the message stays closed for that check-in. Saved on the device.
@riverpod
class DiaryWeeklyCheckInSuccessDismissalController
    extends _$DiaryWeeklyCheckInSuccessDismissalController {
  @override
  String? build() {
    return ref.watch(appPreferencesProvider).getStringSync(_dismissedKey);
  }

  /// Closes the success message of the check-in effective on [dayKey].
  Future<void> dismiss(String dayKey) async {
    state = dayKey;
    await ref.read(appPreferencesProvider).setString(_dismissedKey, dayKey);
  }
}
