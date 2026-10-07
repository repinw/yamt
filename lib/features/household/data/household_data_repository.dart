import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/provider/firebase_storage_provider.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';

part 'household_data_repository.g.dart';

const _householdsCollection = 'households';

/// Deletes the documents and images that a household holds, for example
/// with the household or when nobody can open them any more.
class HouseholdDataRepository {
  /// Creates the repository.
  const new({required this._firestore, required this._storage});

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  /// Deletes the documents and images of [householdId]. The household, its
  /// members and their key entries stay.
  Future<void> wipeHouseholdData(String householdId) async {
    final household = _firestore
        .collection(_householdsCollection)
        .doc(householdId);
    await deleteFirestoreCollections(
      _firestore,
      householdEncryptedCollections.map(household.collection),
    );
    for (final folder in householdImageFolders) {
      await _deleteFolder(
        _storage.ref('$_householdsCollection/$householdId/$folder'),
      );
    }
  }

  Future<void> _deleteFolder(Reference folder) async {
    final result = await folder.listAll();
    for (final item in result.items) {
      await item.delete();
    }
    for (final prefix in result.prefixes) {
      await _deleteFolder(prefix);
    }
  }
}

/// Household data repository, or `null` while Firebase is unavailable.
@riverpod
HouseholdDataRepository? householdDataRepository(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final storage = ref.watch(firebaseStorageProvider);
  if (firestore == null || storage == null) {
    return null;
  }
  return HouseholdDataRepository(firestore: firestore, storage: storage);
}
