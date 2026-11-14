import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/household/application/household_members_provider.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_scope.dart';

part 'shopping_list_scope_controller.g.dart';

const _scopeKey = 'shopping_list_scope_v1';

/// Whether someone else shares the household list. True until the members
/// are known, so the choice does not flicker away for a shared household.
@riverpod
bool shoppingListIsShared(Ref ref) {
  final members = ref.watch(householdMembersProvider).value;
  return members == null || members.length > 1;
}

/// The list the page shows, saved on the device. The household list until
/// the user switches. Alone in the household, both lists are one: then it
/// shows everything. The choice lives in the preferences, so the controller
/// need not stay alive.
@riverpod
class ShoppingListScopeController extends _$ShoppingListScopeController {
  @override
  ShoppingListScope build() {
    if (!ref.watch(shoppingListIsSharedProvider)) return ShoppingListScope.both;
    final stored = ref.watch(appPreferencesProvider).getStringSync(_scopeKey);
    return ShoppingListScope.values.asNameMap()[stored] ??
        ShoppingListScope.household;
  }

  /// Shows [scope] and saves the choice.
  Future<void> select(ShoppingListScope scope) async {
    state = scope;
    await ref.read(appPreferencesProvider).setString(_scopeKey, scope.name);
  }
}
