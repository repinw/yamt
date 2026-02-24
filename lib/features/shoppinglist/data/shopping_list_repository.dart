import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

import 'firestore_shopping_list_repository.dart';
import 'shopping_list_item_store.dart';
import 'shopping_list_repository_contract.dart';
import 'shopping_list_user_session.dart';

part 'shopping_list_repository.g.dart';

@riverpod
ShoppingListRepository shoppingListRepository(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  final currentUserId = authState.asData?.value?.uid;
  return FirestoreShoppingListRepository(
    session: _CurrentShoppingListUserSession(currentUserId: currentUserId),
    store: FirestoreShoppingListItemStore(
      firestore: FirebaseFirestore.instance,
    ),
  );
}

class _CurrentShoppingListUserSession implements ShoppingListUserSession {
  const _CurrentShoppingListUserSession({required String? currentUserId})
    : _currentUserId = currentUserId;

  final String? _currentUserId;

  @override
  String? get currentUserId => _currentUserId;
}
