import 'dart:async';

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_photo_pose_chips.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The day and pose a progress photo moves to.
typedef ProgressPhotoMoveTarget = ({DateTime day, ProgressPhotoPose pose});

/// The sheet that picks another day and pose for [photo]. Pops the
/// [ProgressPhotoMoveTarget].
class ProgressPhotoMoveSheet extends StatefulWidget {
  /// Creates the sheet.
  const new({required this.photo, required this.today, super.key});

  /// Key of the day button.
  static const dayKey = ValueKey<String>('progress-photo-move-day');

  /// Key of the move button.
  static const moveKey = ValueKey<String>('progress-photo-move-save');

  /// The photo that moves.
  final ProgressPhoto photo;

  /// The current day, the latest day a photo can have.
  final DateTime today;

  @override
  State<ProgressPhotoMoveSheet> createState() => _ProgressPhotoMoveSheetState();
}

class _ProgressPhotoMoveSheetState extends State<ProgressPhotoMoveSheet> {
  late DateTime _day = widget.photo.day;
  late ProgressPhotoPose _pose = widget.photo.pose;

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2000),
      lastDate: widget.today,
    );
    if (picked != null && mounted) {
      setState(() => _day = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final unchanged = _day == widget.photo.day && _pose == widget.photo.pose;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Text(
              l10n.progressPhotoMoveTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ProgressPhotoPoseChips(
              selected: _pose,
              onSelected: (pose) => setState(() => _pose = pose),
            ),
            OutlinedButton(
              key: ProgressPhotoMoveSheet.dayKey,
              onPressed: () => unawaited(_pickDay()),
              child: Text(DateFormat.yMMMMEEEEd(localeName).format(_day)),
            ),
            FilledButton(
              key: ProgressPhotoMoveSheet.moveKey,
              onPressed: unchanged
                  ? null
                  : () => Navigator.of(context)
                        .pop<ProgressPhotoMoveTarget>((day: _day, pose: _pose)),
              child: Text(l10n.progressPhotoMove),
            ),
          ],
        ),
      ),
    );
  }
}
