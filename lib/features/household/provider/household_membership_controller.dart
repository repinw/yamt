import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/household/data/household_repository.dart';
import 'package:yamt/features/household/provider/household_invite_code_controller.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_templates_controller.dart';
import 'package:yamt/features/shoppinglist/provider/shopping_list_controller.dart';

part 'household_membership_controller.g.dart';

@riverpod
class HouseholdMembershipController extends _$HouseholdMembershipController {
  @override
  FutureOr<void> build() {}

  Future<void> joinHousehold(String code) async {
    await _runAction(() async {
      await ref.read(householdRepositoryProvider).joinHousehold(code);
      _resetSharedScopeState();
      ref.read(householdInviteCodeControllerProvider.notifier).clear();
    });
  }

  Future<void> leaveHousehold() async {
    await _runAction(() async {
      await ref.read(householdRepositoryProvider).leaveHousehold();
      _resetSharedScopeState();
      ref.read(householdInviteCodeControllerProvider.notifier).clear();
    });
  }

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
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError<void>(error, stackTrace);
      }
      rethrow;
    }
  }

  void _resetSharedScopeState() {
    ref.read(householdDataOwnerRecoveryProvider.notifier).clear();
    ref.invalidate(householdDataOwnerUserIdProvider);
    ref.invalidate(effectiveHouseholdDataOwnerUserIdProvider);
    ref.invalidate(inventoryItemsControllerProvider);
    ref.invalidate(preparedMealsControllerProvider);
    ref.invalidate(preparedMealTemplatesControllerProvider);
    ref.invalidate(shoppingListControllerProvider);
  }
}
