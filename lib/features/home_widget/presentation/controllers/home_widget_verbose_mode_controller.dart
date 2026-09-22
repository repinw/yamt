import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

part 'home_widget_verbose_mode_controller.g.dart';

const _verboseModeKey = 'home_widget_verbose_mode_v1';
const _verboseModeShownValue = 'shown';

/// Whether the home-screen widget shows its verbose layout (eaten / target
/// grams next to each macro bar, like the expanded Diary card) instead of
/// the silent one. The choice is saved on the device.
@riverpod
class HomeWidgetVerboseModeController
    extends _$HomeWidgetVerboseModeController {
  @override
  bool build() {
    final preferences = ref.watch(appPreferencesProvider);
    return preferences.getStringSync(_verboseModeKey) == _verboseModeShownValue;
  }

  /// Switches between the silent and the verbose widget layout.
  Future<void> toggle() async {
    final verbose = !state;
    state = verbose;
    final preferences = ref.read(appPreferencesProvider);
    if (verbose) {
      await preferences.setString(_verboseModeKey, _verboseModeShownValue);
    } else {
      await preferences.remove(_verboseModeKey);
    }
  }
}
