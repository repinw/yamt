import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';
import 'package:yamt/features/shoppinglist/data/firestore_shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_item_store.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository_contract.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_user_session.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

part 'shopping_list_repository.g.dart';

/// Shopping list repository.
@riverpod
ShoppingListRepository shoppingListRepository(Ref ref) {
  ref.watch(authStateChangesProvider);
  final currentUserId = ref.watch(effectiveHouseholdDataOwnerUserIdProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    return const _UnavailableShoppingListRepository();
  }
  return FirestoreShoppingListRepository(
    session: _CurrentShoppingListUserSession(currentUserId: currentUserId),
    store: FirestoreShoppingListItemStore(firestore: firestore),
  );
}

class _CurrentShoppingListUserSession implements ShoppingListUserSession {
  const _CurrentShoppingListUserSession({required String? currentUserId})
    : _currentUserId = currentUserId;

  final String? _currentUserId;

  @override
  String? get currentUserId => _currentUserId;
}

class _UnavailableShoppingListRepository implements ShoppingListRepository {
  const _UnavailableShoppingListRepository();

  @override
  Stream<List<ShoppingListItem>> watchAll() {
    return const Stream<List<ShoppingListItem>>.empty();
  }

  @override
  Future<List<ShoppingListItem>> readAll() async {
    return const <ShoppingListItem>[];
  }

  @override
  Future<bool> saveAll(List<ShoppingListItem> items) async {
    return false;
  }
}
