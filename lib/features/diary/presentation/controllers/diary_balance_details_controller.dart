import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

part 'diary_balance_details_controller.g.dart';

const _detailsKey = 'diary_balance_details_v1';
const _detailsShownValue = 'shown';

/// Whether the daily balance card shows all numbers instead of only what is
/// left. The choice is saved on the device.
@riverpod
class DiaryBalanceDetailsController extends _$DiaryBalanceDetailsController {
  @override
  bool build() {
    final preferences = ref.watch(appPreferencesProvider);
    return preferences.getStringSync(_detailsKey) == _detailsShownValue;
  }

  /// Switches between the quiet and the detailed card.
  Future<void> toggle() async {
    final showDetails = !state;
    state = showDetails;
    final preferences = ref.read(appPreferencesProvider);
    if (showDetails) {
      await preferences.setString(_detailsKey, _detailsShownValue);
    } else {
      await preferences.remove(_detailsKey);
    }
  }
}
