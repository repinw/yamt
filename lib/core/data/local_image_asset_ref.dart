import 'package:yamt/core/data/local_image_store.dart';

const localImageAssetStorageFolder = 'image_assets';

LocalImageRef localImageAssetRef(String assetId) {
  return LocalImageRef(
    storageFolder: localImageAssetStorageFolder,
    entityId: assetId,
  );
}

LocalImageRef? maybeLocalImageAssetRef(String? imageAssetId) {
  final normalizedAssetId = imageAssetId?.trim();
  if (normalizedAssetId == null || normalizedAssetId.isEmpty) {
    return null;
  }
  return localImageAssetRef(normalizedAssetId);
}
