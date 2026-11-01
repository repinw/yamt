import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

part 'diary_pace_marker_controller.g.dart';

const _paceMarkerKey = 'diary_pace_marker_v1';

/// Whether today's kcal line marks where the day should be by now, saved on
/// the device. Off until the user turns it on in the budget card's menu.
@riverpod
class DiaryPaceMarkerController extends _$DiaryPaceMarkerController {
  @override
  bool build() =>
      ref.watch(appPreferencesProvider).getIntSync(_paceMarkerKey) == 1;

  /// Shows the marker when [visible] is true, hides it otherwise, and saves
  /// the choice.
  Future<void> show({required bool visible}) async {
    state = visible;
    final preferences = ref.read(appPreferencesProvider);
    if (visible) {
      await preferences.setInt(_paceMarkerKey, 1);
    } else {
      await preferences.remove(_paceMarkerKey);
    }
  }
}
