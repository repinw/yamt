import 'package:yamt/core/data/local_image_store.dart';

const calorieEntryImageStorageFolder = 'calorie_entries';

LocalImageRef calorieEntryImageRef(String entryId) {
  return LocalImageRef(
    storageFolder: calorieEntryImageStorageFolder,
    entityId: entryId,
  );
}
