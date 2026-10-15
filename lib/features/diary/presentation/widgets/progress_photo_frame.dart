import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/features/health/data/progress_photo_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// A progress photo in a square-cornered portrait frame. The decrypted image
/// lives only in memory.
class ProgressPhotoFrame extends ConsumerWidget {
  /// Creates the frame of the photo [photoId].
  const new({required this.photoId, super.key});

  /// Id of the photo.
  final String photoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final image = ref.watch(progressPhotoBytesProvider(photoId));
    return AspectRatio(
      aspectRatio: AppSizes.progressPhotoAspectRatio,
      child: ColoredBox(
        color: colors.surfaceContainerHighest,
        child: image.when(
          data: (bytes) => Image.memory(
            bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            semanticLabel: AppLocalizations.of(context)!.progressPhotoLabel,
          ),
          loading: () => const SizedBox.expand(),
          error: (_, _) => Icon(
            Icons.broken_image_outlined,
            color: colors.onSurfaceVariant,
            semanticLabel: AppLocalizations.of(context)!
                .progressPhotoLoadFailed,
          ),
        ),
      ),
    );
  }
}
