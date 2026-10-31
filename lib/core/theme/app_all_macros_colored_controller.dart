import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

part 'app_all_macros_colored_controller.g.dart';

const _allMacrosColoredKey = 'app_all_macros_colored_v1';
const _onValue = '1';

/// Whether every macro shows its color, instead of only the one with the
/// lowest share of its target. One choice for every design, saved on the
/// device; off by default.
@riverpod
class AppAllMacrosColoredController extends _$AppAllMacrosColoredController {
  @override
  bool build() =>
      ref.watch(appPreferencesProvider).getStringSync(_allMacrosColoredKey) ==
      _onValue;

  /// Shows every macro in its color, or only the lowest one.
  Future<void> select({required bool value}) async {
    state = value;
    final preferences = ref.read(appPreferencesProvider);
    if (value) {
      await preferences.setString(_allMacrosColoredKey, _onValue);
    } else {
      await preferences.remove(_allMacrosColoredKey);
    }
  }
}
