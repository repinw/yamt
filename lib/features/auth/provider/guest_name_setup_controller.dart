import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/seed_color_controller.dart';
import 'package:yamt/core/theme/theme_mode_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/domain/auth_profile_setup_preferences.dart';
import 'package:yamt/features/auth/domain/auth_user_extensions.dart';
import 'package:yamt/features/auth/provider/auth_repository.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

part 'guest_name_setup_controller.g.dart';

class GuestNameSetupFormDefaults {
  const GuestNameSetupFormDefaults({
    required this.prefilledName,
    required this.seedColor,
    required this.themeMode,
  });

  final String? prefilledName;
  final Color seedColor;
  final ThemeMode themeMode;
}

@riverpod
class GuestNameSetupController extends _$GuestNameSetupController {
  @override
  FutureOr<void> build() {}

  GuestNameSetupFormDefaults initialFormDefaults() {
    final authState = ref.read(authStateChangesProvider);
    final currentUser =
        authState.asData?.value ?? ref.read(firebaseAuthProvider).currentUser;
    final seedColor = ref.read(seedColorControllerProvider);
    final themeMode = ref.read(themeModeControllerProvider);

    if (currentUser == null || currentUser.isAnonymous) {
      return GuestNameSetupFormDefaults(
        prefilledName: null,
        seedColor: seedColor,
        themeMode: themeMode,
      );
    }

    final prefilledName = currentUser.isLikelyFirstSignIn
        ? currentUser.displayName?.trim()
        : null;

    return GuestNameSetupFormDefaults(
      prefilledName: prefilledName?.isEmpty ?? true ? null : prefilledName,
      seedColor: seedColor,
      themeMode: themeMode,
    );
  }

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
