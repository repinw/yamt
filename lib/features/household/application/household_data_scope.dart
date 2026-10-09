import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/household/application/household_key_session.dart';

part 'household_data_scope.g.dart';

/// Everything a household repository needs to read and write the active
/// household's sealed data.
typedef HouseholdDataScope = ({
  String householdId,
  FirebaseFirestore firestore,
  PayloadCipher cipher,
});

/// A household data store bound to the household it reads and writes.
typedef HouseholdStore<S> = ({String householdId, S store});

/// The active household's data scope, or `null` while the household key is
/// not ready or Firestore is unavailable (signed out, session shutdown).
///
/// This is the one place that decides "no household key". Repositories that
/// get `null` read empty and refuse writes.
@riverpod
HouseholdDataScope? householdDataScope(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final household = ref.watch(householdCipherProvider);
  if (firestore == null || household == null) {
    return null;
  }
  return (
    householdId: household.householdId,
    firestore: firestore,
    cipher: household.cipher,
  );
}
