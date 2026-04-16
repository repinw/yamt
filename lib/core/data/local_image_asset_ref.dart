import 'package:yamt/core/data/local_image_store.dart';

/// Storage folder used for image assets stored locally.
const localImageAssetStorageFolder = 'image_assets';

/// Creates local image reference for persisted asset id.
LocalImageRef localImageAssetRef(String assetId) {
  return LocalImageRef(
    storageFolder: localImageAssetStorageFolder,
    entityId: assetId,
  );
}

/// Returns local image reference for asset id, or `null` when blank.
LocalImageRef? maybeLocalImageAssetRef(String? imageAssetId) {
  final normalizedAssetId = imageAssetId?.trim();
  if (normalizedAssetId == null || normalizedAssetId.isEmpty) {
    return null;
  }
  return localImageAssetRef(normalizedAssetId);
}
