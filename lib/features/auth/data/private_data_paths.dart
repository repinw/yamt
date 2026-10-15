import 'dart:developer' show log;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:yamt/core/data/encrypted_payload.dart';
import 'package:yamt/core/data/storage_folder.dart';

const _usersCollection = 'users';
const _progressPhotos = 'progress_photos';

/// The paths of the private collections of [uid] that the data key encrypts.
List<String> privateDataCollections(String uid) {
  final userPath = '$_usersCollection/$uid';
  return <String>[
    '$userPath/calorie_entries',
    '$userPath/planned_entries',
    '$userPath/calorie_settings',
    '$userPath/health_weights',
    '$userPath/health_weight_samples',
    '$userPath/calorie_product_overrides',
    '$userPath/$_progressPhotos',
  ];
}

/// The private fields of [uid] that the data key encrypts.
List<EncryptedDocumentField> privateDataFields(String uid) => [
  EncryptedDocumentField('$_usersCollection/$uid', 'burn_week_run_state'),
];

/// Deletes the private files of [uid], such as the progress photos.
///
/// Best effort: their keys lived in the private documents, so a file that
/// stays can no longer be read, and deleting the account removes it.
Future<void> deletePrivateFiles(FirebaseStorage files, String uid) async {
  try {
    await deleteStorageFolder(
      files.ref('$_usersCollection/$uid/$_progressPhotos'),
    );
  } on Object catch (error, stackTrace) {
    log(
      'Failed to delete the private files; they can no longer be read.',
      name: 'PrivateDataPaths',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
