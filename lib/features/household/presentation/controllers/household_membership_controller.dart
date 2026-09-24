import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/application/'
    'auth_profile_setup_status_provider.dart';
import 'package:yamt/features/auth/data/auth_repository.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/domain/auth_profile_setup_preferences.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/data/household_repository.dart';
import 'package:yamt/features/household/domain/household_invite.dart';
import 'package:yamt/features/household/presentation/controllers/'
    'household_invite_code_controller.dart';

part 'household_membership_controller.g.dart';

/// Defines household membership controller.
@riverpod
class HouseholdMembershipController extends _$HouseholdMembershipController {
  @override
  FutureOr<void> build() {}

  /// Join household.
  Future<void> joinHousehold(
    HouseholdInvite invite, {
    String? displayName,
  }) async {
    await _runAction(() async {
      final normalizedName = displayName?.trim();
      if (normalizedName != null && normalizedName.isNotEmpty) {
        await _updateDisplayName(normalizedName);
      }
      await ref.read(householdRepositoryProvider).joinHousehold(invite);
      _clearHouseholdScopeRecovery();
      ref.invalidate(householdKeySessionProvider);
      ref.read(householdInviteCodeControllerProvider.notifier).clear();
    });
  }

  Future<void> _updateDisplayName(String name) async {
    final repository = ref.read(authRepositoryProvider);
    final preferences = ref.read(appPreferencesProvider);
    final userId = repository.currentUserId;
    await repository.updateCurrentUserDisplayName(displayName: name);
    if (userId != null) {
      await preferences.setString(
        AuthProfileSetupPreferences.keyForUser(userId),
        AuthProfileSetupPreferences.completedValue,
      );
    }
    if (!ref.mounted) {
      return;
    }
    ref
      ..invalidate(authProfileSetupCompletedProvider)
      ..invalidate(authStateChangesProvider);
  }

  /// Leave household.
  Future<void> leaveHousehold() async {
    await _runAction(() async {
      await ref.read(householdRepositoryProvider).leaveHousehold();
      _clearHouseholdScopeRecovery();
      ref.read(householdInviteCodeControllerProvider.notifier).clear();
    });
  }

  /// Remove member.
  Future<void> removeMember(String userId) async {
    await _runAction(() async {
      await ref.read(householdRepositoryProvider).removeMember(userId);
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    state = const AsyncLoading<void>();
    try {
      await action();
      if (!ref.mounted) {
        return;
      }
      state = const AsyncData<void>(null);
    } on Object catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError<void>(error, stackTrace);
      }
      rethrow;
    }
  }

  void _clearHouseholdScopeRecovery() {
    ref.read(householdDataOwnerRecoveryProvider.notifier).clear();
  }
}
