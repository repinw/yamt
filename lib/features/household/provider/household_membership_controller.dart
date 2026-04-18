import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/household/data/household_repository.dart';
import 'package:yamt/features/household/provider/household_invite_code_controller.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';

part 'household_membership_controller.g.dart';

/// Defines household membership controller.
@riverpod
class HouseholdMembershipController extends _$HouseholdMembershipController {
  @override
  FutureOr<void> build() {}

  /// Join household.
  Future<void> joinHousehold(String code) async {
    await _runAction(() async {
      await ref.read(householdRepositoryProvider).joinHousehold(code);
      _clearHouseholdScopeRecovery();
      ref.read(householdInviteCodeControllerProvider.notifier).clear();
    });
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
