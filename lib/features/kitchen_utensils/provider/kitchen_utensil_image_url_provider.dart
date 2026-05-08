import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository.dart';

/// Loads a kitchen utensil image URL.
final FutureProviderFamily<String?, String> kitchenUtensilImageUrlProvider =
    FutureProvider.family<String?, String>((ref, imageStoragePath) {
      return ref
          .watch(kitchenUtensilRepositoryProvider)
          .imageUrl(imageStoragePath);
    });
