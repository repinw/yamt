import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/data/household_invite_repository.dart';
import 'package:yamt/features/household/domain/household_exceptions.dart';
import 'package:yamt/features/household/domain/household_invite.dart';

part 'household_invite_code_controller.g.dart';

/// Holds the invite that the admin created for the active household.
@riverpod
class HouseholdInviteCodeController extends _$HouseholdInviteCodeController {
  @override
  AsyncValue<HouseholdInvite?> build() {
    return const AsyncData<HouseholdInvite?>(null);
  }

  /// Creates a new invite into the active household.
  Future<void> generateInviteCode() async {
    state = const AsyncLoading<HouseholdInvite?>();
    try {
      final repository = ref.read(householdInviteRepositoryProvider);
      final householdId = ref.read(activeHouseholdIdProvider);
      if (repository == null || householdId == null) {
        throw const HouseholdKeyUnavailableException();
      }
      final invite = await repository.generateInvite(householdId);
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

  /// Forgets the invite.
  void clear() {
    state = const AsyncData<HouseholdInvite?>(null);
  }
}
