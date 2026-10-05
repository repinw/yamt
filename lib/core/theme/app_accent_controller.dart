import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_accent.dart';

part 'app_accent_controller.g.dart';

const _accentKey = 'app_accent_v1';

/// The accent color the user picked. The choice is saved on the device;
/// without one, or with one this version does not know, the app uses lime.
@riverpod
class AppAccentController extends _$AppAccentController {
  @override
  AppAccent build() {
    final stored = ref.watch(appPreferencesProvider).getStringSync(_accentKey);
    return AppAccent.values.asNameMap()[stored] ?? AppAccent.lime;
  }

  /// Switches the app to [accent] and saves the choice.
  Future<void> select(AppAccent accent) async {
    state = accent;
    await ref.read(appPreferencesProvider).setString(_accentKey, accent.name);
  }
}
