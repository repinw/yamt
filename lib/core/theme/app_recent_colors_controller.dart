import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

part 'app_recent_colors_controller.g.dart';

const _recentColorsKey = 'app_recent_colors_v1';

/// How many last used colors are kept.
const _maxRecentColors = 6;

/// The colors the user last took in the color picker, newest first, saved
/// on the device.
@riverpod
class AppRecentColorsController extends _$AppRecentColorsController {
  @override
  List<Color> build() {
    final stored = ref
        .watch(appPreferencesProvider)
        .getStringSync(_recentColorsKey);
    if (stored == null || stored.isEmpty) {
      return const [];
    }
    return [for (final value in stored.split(',')) Color(int.parse(value))];
  }

  /// Puts [color] first; an older use of it goes away. Stays alive until the
  /// colors are saved, even when the panel closes meanwhile.
  Future<void> add(Color color) async {
    final link = ref.keepAlive();
    try {
      final colors = [
        color,
        ...state.where((recent) => recent.toARGB32() != color.toARGB32()),
      ].take(_maxRecentColors).toList();
      state = colors;
      await ref
          .read(appPreferencesProvider)
          .setString(
            _recentColorsKey,
            colors.map((recent) => recent.toARGB32()).join(','),
          );
    } finally {
      link.close();
    }
  }
}
