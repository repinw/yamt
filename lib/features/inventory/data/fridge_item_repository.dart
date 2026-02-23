import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'firestore_fridge_item_repository.dart';
import 'fridge_item_repository_contract.dart';
import 'inventory_fridge_item_store.dart';
import 'inventory_user_session.dart';

export 'firestore_fridge_item_repository.dart';
export 'fridge_item_repository_contract.dart';
export 'inventory_fridge_item_store.dart';
export 'inventory_user_session.dart';

part 'fridge_item_repository.g.dart';

@riverpod
FridgeItemRepository fridgeItemRepository(Ref ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return FirestoreFridgeItemRepository(
    session: FirebaseInventoryUserSession(auth: auth),
    store: FirestoreInventoryFridgeItemStore(
      firestore: FirebaseFirestore.instance,
    ),
  );
}
