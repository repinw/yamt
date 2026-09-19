import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sheet_constants.dart';
import 'package:yamt/core/constants/hero_tags.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';

/// Image shown next to the entry name in the details sheet.
///
/// With [heroEnabled] it is the landing spot of the image that flies in from
/// the diary row.
class CalorieEntryThumbnail extends StatelessWidget {
  /// Creates a calorie entry thumbnail.
  const new({
    required this.entry,
    required this.storedImageBytes,
    this.heroEnabled = false,
    super.key,
  });

  /// Entry whose image is displayed.
  final CalorieEntry entry;

  /// Locally stored image bytes when available.
  final Uint8List? storedImageBytes;

  /// Whether the image takes part in the hero flight from the diary.
  final bool heroEnabled;

  @override
  Widget build(BuildContext context) {
    final thumbnail = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg + AppSpacing.xs),
      child: SizedBox.square(
        dimension: AppSheetTokens.heroImageSize,
        child: _EntryImage(entry: entry, storedImageBytes: storedImageBytes),
      ),
    );
    if (!heroEnabled) {
      return thumbnail;
    }
    return Hero(tag: HeroTags.loggedEntryImage(entry.id), child: thumbnail);
  }
}

class _EntryImage extends StatelessWidget {
  const new({required this.entry, required this.storedImageBytes});

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

    return ColoredBox(
      color: colors.surface,
      child: _EntryImageFallback(initial: initial),
    );
  }
}

class _EntryImageFallback extends StatelessWidget {
  const new({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Text(
        initial.toUpperCase(),
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(color: colors.primary, fontWeight: FontWeight.w800),
      ),
    );
  }
}
