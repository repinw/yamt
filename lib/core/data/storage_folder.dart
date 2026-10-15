import 'package:firebase_storage/firebase_storage.dart';

/// Deletes every file under [folder], including its subfolders.
Future<void> deleteStorageFolder(Reference folder) async {
  final result = await folder.listAll();
  for (final item in result.items) {
    await item.delete();
  }
  for (final prefix in result.prefixes) {
    await deleteStorageFolder(prefix);
  }
}
