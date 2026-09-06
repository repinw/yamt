import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';

/// Thumbnail used for meal entry previews and rows.
class MealThumb extends ConsumerWidget {
  /// Creates a meal thumbnail.
  const MealThumb({
    required this.entry,
    this.compact = false,
    super.key,
  });

  /// Entry whose media should be rendered.
  final DiaryMealEntry entry;

  /// Whether to render a compact thumbnail for collapsed entries.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageRef = maybeLocalImageAssetRef(entry.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        compact ? AppRadius.sm : AppRadius.md,
      ),
      child: SizedBox.square(
        dimension: compact ? 34 : 54,
        child: storedImageBytes != null
            ? Image.memory(storedImageBytes, fit: BoxFit.cover)
            : entry.imageUrl == null
            ? MealThumbFallback(label: entry.name, compact: compact)
            : AppCachedNetworkImage(
                imageUrl: entry.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => MealThumbFallback(
                  label: entry.name,
                  compact: compact,
                ),
              ),
      ),
    );
  }
}

/// Initial-letter fallback used when an entry has no loadable image.
class MealThumbFallback extends StatelessWidget {
  /// Creates a meal thumbnail fallback.
  const MealThumbFallback({
    required this.label,
    super.key,
    this.compact = false,
  });

  /// Text used to derive the fallback initial.
  final String label;

  /// Whether to render the compact fallback style.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style:
              (compact
                      ? Theme.of(context).textTheme.labelMedium
                      : Theme.of(context).textTheme.titleLarge)
                  ?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                  ),
        ),
      ),
    );
  }
}
