import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/calories/data/calorie_product_lookup_repository.dart';
import 'package:yamt/features/calories/domain/calorie_barcode_utils.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/domain/product_image_url.dart';

part 'inventory_barcode_image_provider.g.dart';

const _providerLogName = 'InventoryBarcodeImageProvider';
const _providerCacheTtl = Duration(minutes: 10);

@riverpod
Future<String?> inventoryBarcodeImageUrl(Ref ref, String rawBarcode) async {
  final link = ref.keepAlive();
  final disposeTimer = Timer(_providerCacheTtl, link.close);
  ref.onDispose(disposeTimer.cancel);

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

String? _normalizeImageUrl(String? value) {
  final normalized = normalizeProductImageUrl(value);
  if (value != null && value.trim().isNotEmpty && normalized == null) {
    log(
      'Ignoring non-http image URL from cache/lookup.',
      name: _providerLogName,
    );
  }
  return normalized;
}
