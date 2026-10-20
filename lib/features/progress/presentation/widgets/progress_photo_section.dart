import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/features/diary/presentation/progress_photo_capture_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/progress_photo_frame.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/features/progress/application/progress_photo_overview_provider.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/domain/progress_photo_overview.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_photo_pose_chips.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_header.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Before and after photos of a pose in the period of a scope, with links to
/// all photos and to the comparison.
class ProgressPhotoSection extends ConsumerStatefulWidget {
  /// Creates the photo section for [scope].
  const new({required this.scope, super.key});

  /// Which goals the photos cover.
  final ProgressScope scope;

  /// Stable key of the section.
  static const sectionKey = ValueKey<String>('progress-photo-section');

  /// Key of the button that opens all photos.
  static const allKey = ValueKey<String>('progress-photos-all');

  /// Key of the button that opens the comparison.
  static const compareKey = ValueKey<String>('progress-photos-compare');

  /// Key of the button that adds the first photo.
  static const addKey = ValueKey<String>('progress-photos-add');

  @override
  ConsumerState<ProgressPhotoSection> createState() =>
      _ProgressPhotoSectionState();
}

class _ProgressPhotoSectionState extends ConsumerState<ProgressPhotoSection> {
  ProgressPhotoPose _pose = ProgressPhotoPose.front;

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(progressPhotoOverviewProvider(widget.scope))
        .when(
          data: (overview) => _content(context, overview),
          loading: () => const ProgressSectionLoading(),
          error: (_, _) => const ProgressSectionError(),
        );
  }

  Widget _content(BuildContext context, ProgressPhotoOverview overview) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final (:before, :after, :beforeKg, :afterKg, :changeKg, :weeks) = overview
        .beforeAfter(_pose);
    return Column(
      key: ProgressPhotoSection.sectionKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProgressSectionHeader(
          kicker: l10n.progressPhotosKicker,
          value: changeKg == null
              ? '–'
              : NumberFormat('+0.0;−0.0', locale).format(changeKg),
          unit: l10n.caloriesUnitKg,
          lines: [if (weeks != null) l10n.progressPhotosWeeks(weeks)],
        ),
        const SizedBox(height: AppSpacing.md),
        if (overview.photos.isEmpty) ...[
          ProgressSectionNote(
            text: widget.scope is ProgressPastGoalScope
                ? l10n.progressPhotosEmptyPastGoal
                : l10n.progressPhotosEmpty,
          ),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              // A photo taken today does not belong to a past goal.
              if (widget.scope is! ProgressPastGoalScope)
                OutlinedButton.icon(
                  key: ProgressPhotoSection.addKey,
                  onPressed: () => unawaited(showProgressPhotoCapture(context)),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(l10n.progressPhotosAdd),
                ),
              // Photos of other goals stay reachable from a goal scope.
              if (widget.scope != ProgressScope.all)
                TextButton(
                  key: ProgressPhotoSection.allKey,
                  onPressed: () =>
                      unawaited(context.push(AppRoutes.homeProgressPhotos)),
                  child: Text(l10n.progressPhotosAll),
                ),
            ],
          ),
        ] else ...[
          ProgressPhotoPoseChips(
            selected: _pose,
            onSelected: (pose) => setState(() => _pose = pose),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              Expanded(
                child: ProgressPhotoTile(
                  kicker: l10n.progressPhotosBefore,
                  photo: before,
                  weightKg: beforeKg,
                ),
              ),
              Expanded(
                child: ProgressPhotoTile(
                  kicker: l10n.progressPhotosAfter,
                  photo: after,
                  weightKg: afterKg,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            spacing: AppSpacing.xs,
            children: [
              Expanded(
                child: OutlinedButton(
                  key: ProgressPhotoSection.allKey,
                  onPressed: () =>
                      unawaited(context.push(AppRoutes.homeProgressPhotos)),
                  child: Text(l10n.progressPhotosAll),
                ),
              ),
              Expanded(
                child: FilledButton(
                  key: ProgressPhotoSection.compareKey,
                  onPressed: () => unawaited(
                    context.push(
                      AppRoutes.homeProgressPhotoComparePath(
                        pose: _pose.name,
                        scope: widget.scope.name,
                      ),
                    ),
                  ),
                  child: Text(l10n.progressPhotosCompare),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A photo with a kicker above and its day and weight below; an empty frame
/// without a photo.
class ProgressPhotoTile extends StatelessWidget {
  /// Creates the tile.
  const new({
    required this.kicker,
    required this.photo,
    required this.weightKg,
    super.key,
  });

  /// Caption above the photo; shown in upper case.
  final String kicker;

  /// The photo, if any.
  final ProgressPhoto? photo;

  /// The weight shown with the photo.
  final double? weightKg;

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        Text(kicker.toUpperCase(), style: progressKickerStyle(context)),
        if (photo == null)
          AspectRatio(
            aspectRatio: AppSizes.progressPhotoAspectRatio,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          )
        else
          ProgressPhotoFrame(photoId: photo.id),
        Text(
          photo == null ? '–' : progressPhotoCaption(context, photo, weightKg),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// The day of [photo] and, if known, its [weightKg].
String progressPhotoCaption(
  BuildContext context,
  ProgressPhoto photo,
  double? weightKg,
) {
  final locale = Localizations.localeOf(context).toString();
  final day = DateFormat.yMMMd(locale).format(photo.day);
  if (weightKg == null) {
    return day;
  }
  final kg = NumberFormat('0.0', locale).format(weightKg);
  return AppLocalizations.of(context)!.progressPhotoCaption(day, kg);
}
