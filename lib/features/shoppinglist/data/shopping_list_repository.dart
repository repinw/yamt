import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
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
  final householdCipher = ref.watch(householdCipherProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null || householdCipher == null) {
    return const _UnavailableShoppingListRepository();
  }
  return FirestoreShoppingListRepository(
    session: _CurrentShoppingListUserSession(
      currentUserId: householdCipher.ownerUid,
    ),
    store: FirestoreShoppingListItemStore(
      firestore: firestore,
      cipher: householdCipher.cipher,
    ),
  );
}

class _CurrentShoppingListUserSession implements ShoppingListUserSession {
  const new({required this._currentUserId});

  final String? _currentUserId;

  @override
  String? get currentUserId => _currentUserId;
}

class _UnavailableShoppingListRepository implements ShoppingListRepository {
  const new();

  @override
  Stream<List<ShoppingListItem>> watchAll() {
    return Stream<List<ShoppingListItem>>.value(const <ShoppingListItem>[]);
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
