import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/household/data/household_repository.dart';
import 'package:yamt/features/household/domain/household_invite.dart';

part 'household_invite_code_controller.g.dart';

/// Defines household invite code controller.
@riverpod
class HouseholdInviteCodeController extends _$HouseholdInviteCodeController {
  @override
  AsyncValue<HouseholdInvite?> build() {
    return const AsyncData<HouseholdInvite?>(null);
  }

  /// Generate invite code.
  Future<void> generateInviteCode() async {
    state = const AsyncLoading<HouseholdInvite?>();
    try {
      final invite = await ref
          .read(householdRepositoryProvider)
          .generateInviteCode();
      if (!ref.mounted) {
        return;
      }
      state = AsyncData<HouseholdInvite?>(invite);
    } on Object catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError<HouseholdInvite?>(error, stackTrace);
      }
      rethrow;
    }
  }

  /// Clear.
  void clear() {
    state = const AsyncData<HouseholdInvite?>(null);
  }
}
