import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository.dart';

part 'kitchen_utensil_image_url_provider.g.dart';

/// Loads the download URL of a stored kitchen utensil image.
@riverpod
Future<String?> kitchenUtensilImageUrl(Ref ref, String imageStoragePath) {
  return ref.watch(kitchenUtensilRepositoryProvider).imageUrl(imageStoragePath);
}
