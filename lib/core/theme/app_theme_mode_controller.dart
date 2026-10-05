import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

part 'app_theme_mode_controller.g.dart';

const _themeModeKey = 'app_theme_mode_v1';

/// Whether the app is light, dark, or follows the system. The choice is
/// saved on the device; without one the app follows the system.
@riverpod
class AppThemeModeController extends _$AppThemeModeController {
  @override
  ThemeMode build() {
    final stored = ref
        .watch(appPreferencesProvider)
        .getStringSync(_themeModeKey);
    return ThemeMode.values.asNameMap()[stored] ?? ThemeMode.system;
  }

  /// Switches the app to [mode] and saves the choice.
  Future<void> select(ThemeMode mode) async {
    state = mode;
    await ref.read(appPreferencesProvider).setString(_themeModeKey, mode.name);
  }
}
