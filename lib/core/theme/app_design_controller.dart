import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

part 'app_design_controller.g.dart';

/// Kept from the time the choice was only light, dark, or system.
const _designKey = 'app_theme_mode_v1';

/// The designs the user can pick.
enum AppDesign {
  /// Light or dark, as the system is.
  system,

  /// Light Graphit colors.
  light,

  /// Dark Graphit colors.
  dark,

  /// The user's own colors (`AppCustomColors`).
  custom,
}

/// The design the user picked. The choice is saved on the device; without
/// one the app follows the system.
@riverpod
class AppDesignController extends _$AppDesignController {
  @override
  AppDesign build() {
    final stored = ref.watch(appPreferencesProvider).getStringSync(_designKey);
    return AppDesign.values.asNameMap()[stored] ?? AppDesign.system;
  }

  /// Switches the app to [design] and saves the choice.
  Future<void> select(AppDesign design) async {
    state = design;
    await ref.read(appPreferencesProvider).setString(_designKey, design.name);
  }
}
