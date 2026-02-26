import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/seed_color_controller.dart';
import 'package:yamt/core/theme/theme_mode_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/domain/auth_profile_setup_preferences.dart';
import 'package:yamt/features/auth/provider/auth_repository.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

part 'guest_name_setup_controller.g.dart';

@riverpod
class GuestNameSetupController extends _$GuestNameSetupController {
  @override
  FutureOr<void> build() {}

  Future<void> saveDisplayName(
    String displayName, {
    required Color seedColor,
    required ThemeMode themeMode,
  }) async {
    final normalized = displayName.trim();
    if (normalized.isEmpty) {
      return;
    }

    final repository = ref.read(authRepositoryProvider);
    final seedColorController = ref.read(seedColorControllerProvider.notifier);
    final themeModeController = ref.read(themeModeControllerProvider.notifier);
    final preferences = ref.read(appPreferencesProvider);
    final userId = repository.currentUserId;
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(() async {
      await repository.updateCurrentUserDisplayName(displayName: normalized);
      await seedColorController.setSeedColor(seedColor);
      await themeModeController.setThemeMode(themeMode);
      if (userId == null) {
        return;
      }
      await preferences.setString(
        AuthProfileSetupPreferences.keyForUser(userId),
        AuthProfileSetupPreferences.completedValue,
      );
    });
    if (!ref.mounted) {
      return;
    }
    if (!nextState.hasError) {
      ref.invalidate(authStateChangesProvider);
    }
    state = nextState;
  }
}
