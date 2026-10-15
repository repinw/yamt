import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/progress_photo_capture_sheet.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One chip per pose; the [selected] one is filled.
class ProgressPhotoPoseChips extends StatelessWidget {
  /// Creates the pose chips.
  const new({required this.selected, required this.onSelected, super.key});

  /// Key of the chip of [pose].
  static ValueKey<String> poseKey(ProgressPhotoPose pose) =>
      ValueKey<String>('progress-photos-pose-${pose.name}');

  /// The picked pose.
  final ProgressPhotoPose selected;

  /// Called with the tapped pose.
  final ValueChanged<ProgressPhotoPose> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.xs,
      children: [
        for (final pose in ProgressPhotoPose.values)
          ChoiceChip(
            key: poseKey(pose),
            label: Text(progressPhotoPoseLabel(l10n, pose)),
            selected: pose == selected,
            onSelected: (_) => onSelected(pose),
          ),
      ],
    );
  }
}
