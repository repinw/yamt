import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';

const _thumbSize = 54.0;

/// Entry image, or the entry's initial when no image loads.
class MealThumb extends ConsumerWidget {
  /// Creates a meal thumbnail.
  const new({required this.entry, super.key});

  /// Entry whose media should be rendered.
  final DiaryMealEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageRef = maybeLocalImageAssetRef(entry.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;
    final imageUrl = entry.imageUrl;
    final fallback = _MealThumbFallback(label: entry.name);

    return ClipRRect(
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
            color: colors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
