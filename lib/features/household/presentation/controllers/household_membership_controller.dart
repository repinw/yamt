import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/application/'
    'auth_profile_setup_status_provider.dart';
import 'package:yamt/features/auth/data/auth_repository.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/domain/auth_profile_setup_preferences.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/data/household_invite_repository.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/data/household_member_repository.dart';
import 'package:yamt/features/household/data/household_repository.dart';
import 'package:yamt/features/household/domain/household_exceptions.dart';
import 'package:yamt/features/household/domain/household_invite.dart';
import 'package:yamt/features/household/presentation/controllers/'
    'household_invite_code_controller.dart';

part 'household_membership_controller.g.dart';

typedef _HouseholdIds = ({String active, String own});

/// Runs the membership actions of the household page.
@riverpod
class HouseholdMembershipController extends _$HouseholdMembershipController {
  @override
  FutureOr<void> build() {}

  /// Joins the household behind [invite] and sets [displayName] first when
  /// the user has none yet.
  Future<void> joinHousehold(
    HouseholdInvite invite, {
    String? displayName,
  }) async {
    await _runAction(() async {
      // Read before the name update: it reloads the account and its profile.
      final ids = _requireHouseholdIds();
      final invites = _require(ref.read(householdInviteRepositoryProvider));
      final normalizedName = displayName?.trim();
      if (normalizedName != null && normalizedName.isNotEmpty) {
        await _updateDisplayName(normalizedName);
      }
      await invites.joinHousehold(
        invite,
        activeHouseholdId: ids.active,
        ownHouseholdId: ids.own,
      );
      _forgetPreviousHousehold();
    });
  }

  /// Leaves the active household. An admin hands the lead to
  /// [successorUid].
  Future<void> leaveHousehold({String? successorUid}) async {
    await _runAction(() async {
      final ids = _requireHouseholdIds();
      await _require(ref.read(householdRepositoryProvider)).leaveHousehold(
        householdId: ids.active,
        ownHouseholdId: ids.own,
        successorUid: successorUid,
      );
      _forgetPreviousHousehold();
    });
  }

  /// Removes [userId] from the active household.
  Future<void> removeMember(String userId) async {
    await _runAction(() async {
      await _require(ref.read(householdMemberRepositoryProvider))
          .removeMember(_requireHouseholdIds().active, userId);
    });
  }

  /// Hands the lead of the active household to [userId].
  Future<void> makeAdmin(String userId) async {
    await _runAction(() async {
      await _require(ref.read(householdMemberRepositoryProvider))
          .makeAdmin(_requireHouseholdIds().active, userId);
    });
  }

  /// Leaves the household key for [memberUid], who lost it after a fresh
  /// start, and returns the code that opens it.
  Future<RecoveryKey> createKeyRestoreCode(String memberUid) async {
    late RecoveryKey code;
    await _runAction(() async {
      final householdCipher = ref.read(householdCipherProvider);
      final keys = ref.read(householdKeyRepositoryProvider);
      if (householdCipher == null || keys == null) {
        throw const HouseholdKeyUnavailableException();
      }
      code = await keys.saveRestoreCode(
        householdId: householdCipher.householdId,
        memberUid: memberUid,
        householdKey: householdCipher.key,
      );
    });
    return code;
  }

  /// Takes the household key back with a [code] from another member.
  Future<void> restoreHouseholdKey(String code) async {
    await _runAction(
      () => ref.read(householdKeySessionProvider.notifier).restoreKey(code),
    );
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

  _HouseholdIds _requireHouseholdIds() {
    final active = ref.read(activeHouseholdIdProvider);
    final own = ref.read(ownHouseholdIdProvider);
    if (active == null || own == null) {
      throw const HouseholdKeyUnavailableException();
    }
    return (active: active, own: own);
  }

  T _require<T extends Object>(T? repository) {
    if (repository == null) {
      throw StateError('Household actions need a signed-in user.');
    }
    return repository;
  }

  void _forgetPreviousHousehold() {
    if (!ref.mounted) {
      return;
    }
    ref.read(householdDataOwnerRecoveryProvider.notifier).clear();
    ref.read(householdInviteCodeControllerProvider.notifier).clear();
  }
}
