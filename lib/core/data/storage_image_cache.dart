import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Prefix of a Firebase Storage address, such as
/// `gs://bucket/product_images/uid/id/front.jpg`.
const storageImageAddressPrefix = 'gs://';

/// Whether [url] is a Firebase Storage address instead of a web address.
bool isStorageImageAddress(String url) =>
    url.startsWith(storageImageAddressPrefix);

/// Image cache for Firebase Storage addresses.
///
/// An item can store the address of a photo before its upload finishes.
/// The cache holds the local photo under that address, so it shows right
/// away. Only an image missing from the cache is downloaded: then the
/// address becomes a download URL.
final storageImageCacheManager = _StorageImageCacheManager();

// ImageCacheManager lets CachedNetworkImage store resized copies.
class _StorageImageCacheManager extends CacheManager with ImageCacheManager {
  new()
    : super(Config('storageImageCache', fileService: _StorageFileService()));
}

class _StorageFileService extends HttpFileService {
  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    // ponytail: the default Firebase app's Storage; pass an instance if a
    // second app or a signed-out shutdown ever matters here.
    final downloadUrl = await FirebaseStorage.instance
        .refFromURL(url)
        .getDownloadURL();
    return await super.get(downloadUrl, headers: headers);
  }
}
