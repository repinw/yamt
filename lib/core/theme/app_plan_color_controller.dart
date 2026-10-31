import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

part 'app_plan_color_controller.g.dart';

const _planColorKey = 'app_plan_color_v1';

/// The plan color the user picked, used in light and dark alike. The choice
/// is saved on the device; null means the Graphit plan brown of each
/// brightness.
@riverpod
class AppPlanColorController extends _$AppPlanColorController {
  @override
  Color? build() {
    final stored = ref.watch(appPreferencesProvider).getIntSync(_planColorKey);
    return stored == null ? null : Color(stored);
  }

  /// Switches the app to [color] and saves the choice.
  Future<void> select(Color color) async {
    state = color;
    await ref
        .read(appPreferencesProvider)
        .setInt(_planColorKey, color.toARGB32());
  }

  /// Goes back to the Graphit plan brown.
  Future<void> reset() async {
    state = null;
    await ref.read(appPreferencesProvider).remove(_planColorKey);
  }
}
