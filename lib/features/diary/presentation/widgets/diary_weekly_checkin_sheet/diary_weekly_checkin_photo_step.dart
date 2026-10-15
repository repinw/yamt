import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/graphit_text_styles.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_weekly_checkin_photos_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_weekly_checkin_sheet_controller.dart';
import 'package:yamt/features/diary/presentation/progress_photo_capture_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_number_format.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_frame.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/progress_photo_capture_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/progress_photo_frame.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Step 3: the first, a middle, and today's progress photo of a pose since
/// the goal start. The slot of today adds or replaces today's photo.
class DiaryWeeklyCheckInPhotoStep extends ConsumerStatefulWidget {
  /// Creates the photo step.
  const new({
    required this.sheet,
    required this.today,
    required this.format,
    super.key,
  });

  /// Controller of the check-in sheet, whose plan the photos follow.
  final DiaryWeeklyCheckInSheetControllerProvider sheet;

  /// The current day.
  final DateTime today;

  /// Number formats.
  final DiaryWeeklyCheckInNumberFormat format;

  @override
  ConsumerState<DiaryWeeklyCheckInPhotoStep> createState() =>
      _DiaryWeeklyCheckInPhotoStepState();
}

class _DiaryWeeklyCheckInPhotoStepState
    extends ConsumerState<DiaryWeeklyCheckInPhotoStep> {
  ProgressPhotoPose _pose = ProgressPhotoPose.front;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sheet =
        widget.sheet.argument! as ({DateTime? windowStart, bool preview});
    final photos = ref.watch(
      diaryWeeklyCheckInPhotosProvider(
        _pose,
        widget.today,
        windowStart: sheet.windowStart,
        preview: sheet.preview,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiaryWeeklyCheckInHeading(
          title: l10n.diaryCheckInPhotoTitle,
          subtitle: l10n.diaryCheckInPhotoSubtitle,
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final pose in ProgressPhotoPose.values)
              ChoiceChip(
                key: DiaryWeeklyCheckInSheetKeys.photoPose(pose.name),
                label: Text(progressPhotoPoseLabel(l10n, pose)),
                selected: pose == _pose,
                onSelected: (_) => setState(() => _pose = pose),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        photos.when(
          data: (photos) => _slots(l10n, photos),
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
          error: (_, _) => Text(l10n.progressPhotosLoadFailed),
        ),
      ],
    );
  }

  Widget _slots(
    AppLocalizations l10n,
    ({
      DiaryWeeklyCheckInPhoto? first,
      DiaryWeeklyCheckInPhoto? middle,
      DiaryWeeklyCheckInPhoto? today,
    })
    milestones,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        Expanded(
          child: _Slot(
            kicker: l10n.diaryCheckInPhotoFirst,
            photo: milestones.first?.photo,
            caption: _caption(milestones.first),
          ),
        ),
        Expanded(
          child: _Slot(
            kicker: l10n.diaryCheckInPhotoMiddle,
            photo: milestones.middle?.photo,
            caption: _caption(milestones.middle),
          ),
        ),
        Expanded(
          child: _Slot(
            kicker: l10n.diaryCheckInPhotoNew,
            photo: milestones.today?.photo,
            caption: _caption(milestones.today),
            // The new photo shows in this slot; no snack bar is needed.
            onAdd: () => unawaited(
              showProgressPhotoCapture(
                context,
                pose: _pose,
                confirmSaved: false,
              ),
            ),
            addLabel: l10n.diaryCheckInPhotoAdd,
          ),
        ),
      ],
    );
  }

  String? _caption(DiaryWeeklyCheckInPhoto? entry) {
    if (entry == null) {
      return null;
    }
    final day = widget.format.day(entry.photo.day);
    final weight = entry.weightKg;
    return weight == null
        ? day
        : AppLocalizations.of(context)!
              .progressPhotoCaption(day, widget.format.kg(weight));
  }
}

/// One column: a kicker, the photo or an empty frame, and its caption.
class _Slot extends StatelessWidget {
  const new({
    required this.kicker,
    required this.photo,
    required this.caption,
    this.onAdd,
    this.addLabel,
  });

  final String kicker;
  final ProgressPhoto? photo;
  final String? caption;

  /// Adds today's photo; only the slot of today has it.
  final VoidCallback? onAdd;
  final String? addLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = this.photo;
    final caption = this.caption;
    final onAdd = this.onAdd;
    final picture = photo == null
        ? AspectRatio(
            aspectRatio: AppSizes.progressPhotoAspectRatio,
            child: ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: onAdd == null
                  ? null
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo_outlined),
                        Text(addLabel ?? '', style: theme.textTheme.labelLarge),
                      ],
                    ),
            ),
          )
        : ProgressPhotoFrame(photoId: photo.id);
    final frame = onAdd == null
        ? picture
        : AppInkWell(
            key: DiaryWeeklyCheckInSheetKeys.photoAdd,
            onTap: onAdd,
            child: picture,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        Text(kicker.toUpperCase(), style: context.graphitKickerStyle),
        frame,
        Text(caption ?? '–', style: theme.textTheme.bodySmall),
      ],
    );
  }
}
