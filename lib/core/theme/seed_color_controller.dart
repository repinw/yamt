import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';

part 'seed_color_controller.g.dart';

/// Manages persisted seed color selection.
@Riverpod(keepAlive: true)
class SeedColorController extends _$SeedColorController {
  static const String _seedColorKey = 'preferred_seed_color';

  @override
  Color build() {
    final preferences = ref.read(appPreferencesProvider);
    final storedColorValue = preferences.getIntSync(_seedColorKey);
    if (storedColorValue != null) {
      if (_isSupportedColor(storedColorValue)) {
        return Color(storedColorValue);
      }
      unawaited(preferences.setInt(_seedColorKey, AppColors.seed.toARGB32()));
      return AppColors.seed;
    }

    unawaited(_loadSavedSeedColor());
    return AppColors.seed;
  }

  /// Updates UI immediately without persisting color yet.
  void previewSeedColor(Color color) {
    if (state.toARGB32() == color.toARGB32()) {
      return;
    }
    state = color;
  }

  /// Persists chosen seed color.
  Future<void> setSeedColor(Color color) async {
    state = color;
    await ref
        .read(appPreferencesProvider)
        .setInt(_seedColorKey, color.toARGB32());
  }

  Future<void> _loadSavedSeedColor() async {
    final storedColorValue = await ref
        .read(appPreferencesProvider)
        .getInt(_seedColorKey);
    if (!ref.mounted || storedColorValue == null) {
      return;
    }

    if (!_isSupportedColor(storedColorValue)) {
      await ref
          .read(appPreferencesProvider)
          .setInt(_seedColorKey, AppColors.seed.toARGB32());
      return;
    }

    state = Color(storedColorValue);
  }

  bool _isSupportedColor(int colorValue) {
    return AppSeedColors.values.any((color) => color.toARGB32() == colorValue);
  }
}
