import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/diary/presentation/widgets/progress_photo_frame.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/features/progress/application/progress_photo_overview_provider.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/domain/progress_photo_overview.dart';
import 'package:yamt/features/progress/presentation/controllers/progress_photo_delete_controller.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_photo_section.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_header.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// All progress photos, grouped by goal, newest first. A long press deletes
/// a photo.
class ProgressPhotosPage extends ConsumerWidget {
  /// Creates the photos page.
  const new({super.key});

  /// Key of the thumbnail of [photoId].
  static ValueKey<String> photoKey(String photoId) =>
      ValueKey<String>('progress-photos-photo-$photoId');

  /// Key of the delete button in the confirm dialog.
  static const deleteConfirmKey = ValueKey<String>(
    'progress-photos-delete-confirm',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final overview = ref.watch(
      progressPhotoOverviewProvider(ProgressScope.all),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.progressPhotosTitle)),
      body: overview.when(
        data: (overview) => overview.photos.isEmpty
            ? Padding(
                padding: responsivePagePadding(
                  context,
                  top: AppSpacing.md,
                  bottom: AppSpacing.xl,
                ),
                child: ProgressSectionNote(text: l10n.progressPhotosEmpty),
              )
            : _PhotoList(overview: overview),
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (_, _) => Padding(
          padding: responsivePagePadding(
            context,
            top: AppSpacing.md,
            bottom: AppSpacing.xl,
          ),
          child: ProgressSectionNote(text: l10n.progressPhotosLoadFailed),
        ),
      ),
    );
  }

  static String _groupTitle(BuildContext context, ProgressPhotoGroup group) {
    final l10n = AppLocalizations.of(context)!;
    final goal = group.goal;
    if (goal == null) {
      return l10n.progressPhotosBeforeGoals;
    }
    final locale = Localizations.localeOf(context).toString();
    return l10n.progressPhotosGoalGroup(
      goal.number,
      DateFormat.yMMMd(locale).format(goal.day),
    );
  }
}

/// One day: its date and weight, then one thumbnail per pose.
class _DayRow extends ConsumerWidget {
  const new({required this.day, required this.overview});

  final ProgressPhotoDay day;
  final ProgressPhotoOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final first = day.poses.values.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.xs,
        children: [
          Text(
            progressPhotoCaption(context, first, overview.weightKg(first)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Row(
            spacing: AppSpacing.xs,
            children: [
              for (final pose in ProgressPhotoPose.values)
                Expanded(
                  child: switch (day.poses[pose]) {
                    final photo? => Semantics(
                      onLongPressHint: AppLocalizations.of(context)!
                          .progressPhotoDelete,
                      child: GestureDetector(
                        key: ProgressPhotosPage.photoKey(photo.id),
                        onLongPress: () => _confirmDelete(context, ref, photo),
                        child: ProgressPhotoFrame(photoId: photo.id),
                      ),
                    ),
                    null => AspectRatio(
                      aspectRatio: AppSizes.progressPhotoAspectRatio,
                      child: ColoredBox(color: colors.surfaceContainerHighest),
                    ),
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProgressPhoto photo,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.progressPhotoDeleteTitle),
        content: Text(l10n.progressPhotoDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            key: ProgressPhotosPage.deleteConfirmKey,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.progressPhotoDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final deleted = await ref
        .read(progressPhotoDeleteControllerProvider.notifier)
        .delete(photo.id);
    if (!deleted && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.progressPhotoDeleteFailed)));
    }
  }
}

/// The goal headers and the day rows of every group, built lazily.
class _PhotoList extends StatelessWidget {
  const new({required this.overview});

  final ProgressPhotoOverview overview;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget Function()>[
      for (final group in overview.groups) ...[
        () => Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            ProgressPhotosPage._groupTitle(context, group).toUpperCase(),
            style: progressKickerStyle(context),
          ),
        ),
        for (final day in group.days)
          () => _DayRow(day: day, overview: overview),
      ],
    ];
    return ListView.builder(
      padding: responsivePagePadding(
        context,
        top: AppSpacing.md,
        bottom: AppSpacing.xl,
      ),
      itemCount: rows.length,
      itemBuilder: (context, index) => rows[index](),
    );
  }
}
