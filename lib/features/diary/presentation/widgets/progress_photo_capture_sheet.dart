import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/utils/flexible_decimal_parser.dart';
import 'package:yamt/features/diary/presentation/controllers/progress_photo_capture_controller.dart';
import 'package:yamt/features/health/data/progress_photo_repository.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The sheet that adds a progress photo: the pose, the day, an optional
/// weight, and the camera or the gallery. A past day and a typed weight
/// let the user add photos from before the app.
///
/// Pops `true` once the photo is saved.
class ProgressPhotoCaptureSheet extends ConsumerStatefulWidget {
  /// Creates the sheet.
  const new({required this.today, super.key});

  /// Key of the camera button.
  static const cameraKey = ValueKey<String>('progress-photo-camera');

  /// Key of the gallery button.
  static const galleryKey = ValueKey<String>('progress-photo-gallery');

  /// Key of the weight field.
  static const weightKey = ValueKey<String>('progress-photo-weight');

  /// Key of the day button.
  static const dayKey = ValueKey<String>('progress-photo-day');

  /// Key of the chip of [pose].
  static ValueKey<String> poseKey(ProgressPhotoPose pose) =>
      ValueKey<String>('progress-photo-pose-${pose.name}');

  /// The current day, the latest day a photo can have.
  final DateTime today;

  @override
  ConsumerState<ProgressPhotoCaptureSheet> createState() =>
      _ProgressPhotoCaptureSheetState();
}

class _ProgressPhotoCaptureSheetState
    extends ConsumerState<ProgressPhotoCaptureSheet> {
  final _weight = TextEditingController();
  ProgressPhotoPose _pose = ProgressPhotoPose.front;
  late DateTime _day = widget.today;
  var _weightInvalid = false;

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

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

  Future<void> _capture(ImageSource source) async {
    final typed = _weight.text.trim();
    final weightKg = typed.isEmpty ? null : parseFlexibleDecimal(typed);
    final weightInvalid =
        typed.isNotEmpty && (weightKg == null || weightKg <= 0);
    setState(() => _weightInvalid = weightInvalid);
    if (weightInvalid) {
      return;
    }
    final saved = await ref
        .read(progressPhotoCaptureControllerProvider.notifier)
        .capture(source: source, day: _day, pose: _pose, weightKg: weightKg);
    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final kick = theme.textTheme.labelSmall?.copyWith(color: muted);
    final capture = ref.watch(progressPhotoCaptureControllerProvider);
    final saving = capture.isLoading;
    final replaces = ref.watch(progressPhotoExistsProvider(_day, _pose));
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Text(
              l10n.progressPhotoCaptureTitle,
              style: theme.textTheme.titleLarge,
            ),
            Text(l10n.progressPhotoPoseLabel.toUpperCase(), style: kick),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final pose in ProgressPhotoPose.values)
                  ChoiceChip(
                    key: ProgressPhotoCaptureSheet.poseKey(pose),
                    label: Text(progressPhotoPoseLabel(l10n, pose)),
                    selected: pose == _pose,
                    onSelected: saving
                        ? null
                        : (_) => setState(() => _pose = pose),
                  ),
              ],
            ),
            Text(l10n.progressPhotoDayLabel.toUpperCase(), style: kick),
            FilledButton.tonal(
              key: ProgressPhotoCaptureSheet.dayKey,
              onPressed: saving ? null : () => unawaited(_pickDay()),
              child: Text(DateFormat.yMMMMEEEEd(localeName).format(_day)),
            ),
            TextField(
              key: ProgressPhotoCaptureSheet.weightKey,
              controller: _weight,
              enabled: !saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.progressPhotoWeightLabel,
                helperText: l10n.progressPhotoWeightHelper,
                errorText: _weightInvalid
                    ? l10n.progressPhotoWeightInvalid
                    : null,
              ),
            ),
            if (replaces)
              Text(
                l10n.progressPhotoReplaceHint,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            if (capture.hasError)
              Text(
                l10n.progressPhotoSaveFailed,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            if (saving) const LinearProgressIndicator(),
            Row(
              spacing: AppSpacing.sm,
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    key: ProgressPhotoCaptureSheet.galleryKey,
                    onPressed: saving
                        ? null
                        : () => unawaited(_capture(ImageSource.gallery)),
                    child: Text(l10n.progressPhotoFromGallery),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    key: ProgressPhotoCaptureSheet.cameraKey,
                    onPressed: saving
                        ? null
                        : () => unawaited(_capture(ImageSource.camera)),
                    child: Text(l10n.progressPhotoCamera),
                  ),
                ),
              ],
            ),
            Row(
              spacing: AppSpacing.xs,
              children: [
                Icon(Icons.lock_outline_rounded, color: muted),
                Expanded(
                  child: Text(
                    l10n.progressPhotoPrivacy,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The name of [pose].
String progressPhotoPoseLabel(AppLocalizations l10n, ProgressPhotoPose pose) {
  return switch (pose) {
    ProgressPhotoPose.front => l10n.progressPhotoPoseFront,
    ProgressPhotoPose.side => l10n.progressPhotoPoseSide,
    ProgressPhotoPose.back => l10n.progressPhotoPoseBack,
  };
}
