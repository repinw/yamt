import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/seed_color_controller.dart';
import 'package:yamt/core/theme/theme_mode_controller.dart';
import 'package:yamt/features/auth/domain/auth_profile_setup_preferences.dart';
import 'package:yamt/features/auth/provider/'
    'auth_profile_setup_status_provider.dart';
import 'package:yamt/features/auth/provider/auth_repository.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

part 'guest_name_setup_controller.g.dart';

/// Whether guest setup can be canceled.
@riverpod
bool canCancelGuestSetup(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  final currentUser =
      authState.asData?.value ?? ref.watch(firebaseAuthProvider).currentUser;
  return currentUser?.isAnonymous ?? false;
}

/// Defines guest name setup form defaults.
class GuestNameSetupFormDefaults {
  /// The guest name setup form defaults.
  const GuestNameSetupFormDefaults({
    required this.prefilledName,
    required this.seedColor,
    required this.themeMode,
  });

  /// The prefilled name.
  final String? prefilledName;

  /// The seed color.
  final Color seedColor;

  /// The theme mode.
  final ThemeMode themeMode;
}

/// Defines guest name setup controller.
@riverpod
class GuestNameSetupController extends _$GuestNameSetupController {
  @override
  FutureOr<void> build() {}

  /// Initial form defaults.
  GuestNameSetupFormDefaults initialFormDefaults() {
    final currentUser = _currentUser();
    final seedColor = ref.read(seedColorControllerProvider);
    final themeMode = ref.read(themeModeControllerProvider);

    if (currentUser == null || currentUser.isAnonymous) {
      return GuestNameSetupFormDefaults(
        prefilledName: null,
        seedColor: seedColor,
        themeMode: themeMode,
      );
    }

    final prefilledName = currentUser.displayName?.trim();

    return GuestNameSetupFormDefaults(
      prefilledName: prefilledName?.isEmpty ?? true ? null : prefilledName,
      seedColor: seedColor,
      themeMode: themeMode,
    );
  }

  /// Cancel anonymous guest setup and return to auth.
  Future<void> cancelGuestSetup() async {
    if (!ref.read(canCancelGuestSetupProvider)) {
      return;
    }

    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(
      ref.read(firebaseAuthProvider).signOut,
    );
    if (!ref.mounted) {
      return;
    }
    if (!nextState.hasError) {
      ref.invalidate(authStateChangesProvider);
    }
    state = nextState;
  }

  /// Save display name.
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
      ref
        ..invalidate(authProfileSetupCompletedProvider)
        ..invalidate(authStateChangesProvider);
    }
    state = nextState;
  }

  User? _currentUser() {
    final authState = ref.read(authStateChangesProvider);
    return authState.asData?.value ??
        ref.read(firebaseAuthProvider).currentUser;
  }
}
