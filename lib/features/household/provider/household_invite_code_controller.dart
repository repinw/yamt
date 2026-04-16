import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/household/data/household_repository.dart';

part 'household_invite_code_controller.g.dart';

/// Defines household invite code controller.
@riverpod
class HouseholdInviteCodeController extends _$HouseholdInviteCodeController {
  @override
  AsyncValue<String?> build() {
    return const AsyncData<String?>(null);
  }

  /// Generate invite code.
  Future<void> generateInviteCode() async {
    state = const AsyncLoading<String?>();
    try {
      final inviteCode = await ref
          .read(householdRepositoryProvider)
          .generateInviteCode();
      if (!ref.mounted) {
        return;
      }
      state = AsyncData<String?>(inviteCode);
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError<String?>(error, stackTrace);
      }
      rethrow;
    }
  }

  /// Clear.
  void clear() {
    state = const AsyncData<String?>(null);
  }
}
