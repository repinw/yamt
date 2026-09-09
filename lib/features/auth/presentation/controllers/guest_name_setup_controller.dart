import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/application/'
    'auth_profile_setup_status_provider.dart';
import 'package:yamt/features/auth/data/auth_repository.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/domain/auth_profile_setup_preferences.dart';

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
  });

  /// The prefilled name.
  final String? prefilledName;
}

/// Defines guest name setup controller.
@riverpod
class GuestNameSetupController extends _$GuestNameSetupController {
  @override
  FutureOr<void> build() {}

  /// Initial form defaults.
  GuestNameSetupFormDefaults initialFormDefaults() {
    final currentUser = _currentUser();

    if (currentUser == null || currentUser.isAnonymous) {
      return const GuestNameSetupFormDefaults(
        prefilledName: null,
      );
    }

    final prefilledName = currentUser.displayName?.trim();

    return GuestNameSetupFormDefaults(
      prefilledName: prefilledName?.isEmpty ?? true ? null : prefilledName,
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
  Future<void> saveDisplayName(String displayName) async {
    final normalized = displayName.trim();
    if (normalized.isEmpty) {
      return;
    }

    final repository = ref.read(authRepositoryProvider);
    final preferences = ref.read(appPreferencesProvider);
    final userId = repository.currentUserId;
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(() async {
      await repository.updateCurrentUserDisplayName(displayName: normalized);
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
