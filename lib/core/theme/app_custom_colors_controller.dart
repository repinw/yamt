import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_accent_controller.dart';
import 'package:yamt/core/theme/app_custom_colors.dart';
import 'package:yamt/core/theme/app_theme.dart';

part 'app_custom_colors_controller.g.dart';

const _customColorsKey = 'app_custom_colors_v1';

/// The colors of the design "Individuell", saved on the device. Null until
/// the user first picks the design.
@riverpod
class AppCustomColorsController extends _$AppCustomColorsController {
  // The colors as saved, while [preview] shows others.
  AppCustomColors? _saved;

  @override
  AppCustomColors? build() {
    final stored = ref
        .watch(appPreferencesProvider)
        .getStringSync(_customColorsKey);
    return _saved = stored == null
        ? null
        : AppCustomColors.fromJson(jsonDecode(stored) as Map<String, Object?>);
  }

  /// Starts the colors, or starts them over, as a copy of the light or dark
  /// design with the accent the user picked there.
  Future<void> start(Brightness base) => _save(_copyOf(base));

  /// Sets [key] to [color].
  Future<void> select(AppCustomColor key, Color color) =>
      _save(state!.withColor(key, color));

  /// Saves [colors] as they were before, for undo.
  Future<void> restore(AppCustomColors colors) => _save(colors);

  /// Shows [key] in [color] across the app without saving it, while the
  /// user is still picking.
  void preview(AppCustomColor key, Color color) =>
      state = state!.withColor(key, color);

  /// Drops the colors shown by [preview] and goes back to the saved ones.
  void discard() {
    if (ref.mounted) {
      state = _saved;
    }
  }

  AppCustomColors _copyOf(Brightness base) {
    final accent = ref.read(appAccentControllerProvider);
    return AppCustomColors.copyOf(
      base == Brightness.dark
          ? AppTheme.dark(accent: accent)
          : AppTheme.light(accent: accent),
    );
  }

  Future<void> _save(AppCustomColors colors) async {
    state = _saved = colors;
    await ref
        .read(appPreferencesProvider)
        .setString(_customColorsKey, jsonEncode(colors.toJson()));
  }
}
