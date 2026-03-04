import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/calories/data/calorie_product_lookup_repository.dart';
import 'package:yamt/features/calories/domain/calorie_barcode_utils.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

part 'inventory_barcode_image_provider.g.dart';

const _providerLogName = 'InventoryBarcodeImageProvider';
const _offImageHost = 'world.openfoodfacts.org';

@riverpod
Future<String?> inventoryBarcodeImageUrl(Ref ref, String rawBarcode) async {
  final barcode = normalizeBarcode(rawBarcode);
  if (!isSupportedBarcode(barcode)) {
    return null;
  }

  final cacheRepository = ref.read(calorieProductCacheRepositoryProvider);
  final cached = await _readCachedImageUrl(cacheRepository, barcode);
  if (cached != null) {
    return cached;
  }

  final lookupRepository = ref.read(calorieProductLookupRepositoryProvider);
  final outcome = await lookupRepository.lookupByBarcode(barcode);
  final profile = _pickProfileFromOutcome(outcome);
  final imageUrl = _normalizeImageUrl(profile?.imageUrl);
  if (profile != null && _shouldPersistGlobalProfile(profile, imageUrl)) {
    await lookupRepository.persistGlobalProduct(
      imageUrl == profile.imageUrl
          ? profile
          : profile.copyWith(imageUrl: imageUrl),
    );
  }
  return imageUrl;
}

Future<String?> _readCachedImageUrl(
  CalorieProductCacheRepositoryContract cacheRepository,
  String barcode,
) async {
  final overrideProfile = await cacheRepository.readUserOverride(barcode);
  final overrideImage = _normalizeImageUrl(overrideProfile?.imageUrl);
  if (overrideImage != null) {
    return overrideImage;
  }

  final globalProfile = await cacheRepository.readGlobalProduct(barcode);
  return _normalizeImageUrl(globalProfile?.imageUrl);
}

CalorieProductProfile? _pickProfileFromOutcome(CalorieLookupOutcome outcome) {
  return switch (outcome.status) {
    CalorieLookupStatus.foundSingle => outcome.product,
    CalorieLookupStatus.foundMultiple => _pickCandidateProfile(
      outcome.candidates,
    ),
    CalorieLookupStatus.notFound => null,
    CalorieLookupStatus.failed => null,
  };
}

CalorieProductProfile? _pickCandidateProfile(
  List<CalorieProductCandidate> candidates,
) {
  if (candidates.isEmpty) {
    return null;
  }
  for (final candidate in candidates) {
    if (_normalizeImageUrl(candidate.profile.imageUrl) != null) {
      return candidate.profile;
    }
  }
  return candidates.first.profile;
}

bool _shouldPersistGlobalProfile(
  CalorieProductProfile profile,
  String? normalizedImageUrl,
) {
  final source = profile.source;
  final isOffProfile =
      source == CalorieProductSource.offBarcode ||
      source == CalorieProductSource.offSearch;
  return isOffProfile && normalizedImageUrl != null;
}

String? _normalizeImageUrl(String? value) {
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed.startsWith('//')) {
    return 'https:$trimmed';
  }
  if (trimmed.startsWith('/')) {
    return 'https://$_offImageHost$trimmed';
  }
  if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
    log(
      'Ignoring non-http image URL from cache/lookup.',
      name: _providerLogName,
    );
    return null;
  }
  return trimmed;
}
