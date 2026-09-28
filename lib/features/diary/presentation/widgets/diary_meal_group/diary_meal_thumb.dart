import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/hero_tags.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';

const _thumbSize = 44.0;

/// Entry image, or the entry's initial when no image loads.
class MealThumb extends ConsumerWidget {
  /// Creates a meal thumbnail for [entry].
  ///
  /// With [heroEnabled] the image flies into the entry details page on
  /// open. Only rows that open one entry enable it: a merged row stands for
  /// several entries and must not share a tag with its children.
  new({required DiaryMealEntry entry, bool heroEnabled = false, super.key})
    : name = entry.name,
      imageUrl = entry.imageUrl,
      imageAssetId = entry.imageAssetId,
      heroEntryId = heroEnabled ? entry.id : null;

  /// Creates a thumbnail for one food of a combined entry.
  new food({required CalorieEntryBundleComponent food, super.key})
    : name = food.name,
      imageUrl = food.imageUrl,
      imageAssetId = null,
      heroEntryId = null;

  /// Name whose initial shows without an image.
  final String name;

  /// Image address.
  final String? imageUrl;

  /// Local image asset id.
  final String? imageAssetId;

  /// Entry whose image flies into its details page, or null.
  final String? heroEntryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageRef = maybeLocalImageAssetRef(imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;
    final imageUrl = this.imageUrl;
    final fallback = _MealThumbFallback(label: name);
    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox.square(
        dimension: _thumbSize,
        child: storedImageBytes != null
            ? Image.memory(storedImageBytes, fit: BoxFit.cover)
            : imageUrl == null
            ? fallback
            : AppCachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
    final hasImage = storedImageBytes != null || imageUrl != null;

    final heroEntryId = this.heroEntryId;
    if (heroEntryId == null || !hasImage) {
      return thumb;
    }
    return Hero(tag: HeroTags.loggedEntryImage(heroEntryId), child: thumb);
  }
}

class _MealThumbFallback extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);
    return ColoredBox(
      color: colors.primary.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: theme.textTheme.titleLarge?.copyWith(
            color: colors.secondary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
