import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';

/// Thumbnail image shown in the calorie entry overview.
class CalorieEntryThumbnail extends StatelessWidget {
  /// Creates a calorie entry thumbnail.
  const CalorieEntryThumbnail({
    required this.entry,
    required this.storedImageBytes,
    super.key,
  });

  /// Entry whose image is displayed.
  final CalorieEntry entry;

  /// Locally stored image bytes when available.
  final Uint8List? storedImageBytes;

  static const _imageSize = 76.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg + AppSpacing.xs),
      child: SizedBox.square(
        dimension: _imageSize,
        child: _EntryImage(
          entry: entry,
          storedImageBytes: storedImageBytes,
        ),
      ),
    );
  }
}

class _EntryImage extends StatelessWidget {
  const _EntryImage({required this.entry, required this.storedImageBytes});

  final CalorieEntry entry;
  final Uint8List? storedImageBytes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trimmedName = entry.name.trim();
    final initial = trimmedName.isEmpty ? '?' : trimmedName.substring(0, 1);
    final imageUrl = entry.imageUrl?.trim();
    final hasImageUrl = imageUrl != null && imageUrl.isNotEmpty;

    if (storedImageBytes != null) {
      return Image.memory(
        storedImageBytes!,
        key: CaloriesPageKeys.entryImage(entry.id),
        fit: BoxFit.cover,
      );
    }

    if (hasImageUrl) {
      return AppCachedNetworkImage(
        imageUrl: imageUrl,
        key: CaloriesPageKeys.entryImage(entry.id),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _EntryImageFallback(initial: initial),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppEditorialSurfaces.backdropGradient(colors),
      ),
      child: _EntryImageFallback(initial: initial),
    );
  }
}

class _EntryImageFallback extends StatelessWidget {
  const _EntryImageFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Text(
        initial.toUpperCase(),
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
