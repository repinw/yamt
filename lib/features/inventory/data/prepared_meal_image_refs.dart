import 'package:yamt/core/data/local_image_store.dart';

const preparedMealImageStorageFolder = 'prepared_meals';
const preparedMealTemplateImageStorageFolder = 'prepared_meal_templates';

LocalImageRef preparedMealImageRef(String mealId) {
  return LocalImageRef(
    storageFolder: preparedMealImageStorageFolder,
    entityId: mealId,
  );
}

LocalImageRef preparedMealTemplateImageRef(String templateId) {
  return LocalImageRef(
    storageFolder: preparedMealTemplateImageStorageFolder,
    entityId: templateId,
  );
}
