import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_dropdown_button.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/diary/presentation/widgets/progress_photo_frame.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/features/progress/application/progress_photo_overview_provider.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/domain/progress_photo_overview.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_photo_pose_chips.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_photo_section.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_header.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Before and after photo of one pose on top of each other; a slider moves
/// the border between them. Both days can be picked.
class ProgressPhotoComparePage extends ConsumerStatefulWidget {
  /// Creates the comparison, opened with the pose named [poseName] in the
  /// scope named [scopeName].
  const new({this.poseName, this.scopeName, super.key});

  /// Name of the pose to start with; front when unknown.
  final String? poseName;

  /// Name of the Fortschritt scope whose photos the comparison covers; all
  /// photos when unknown.
  final String? scopeName;

  /// Key of the day picker of the before side.
  static const beforeKey = ValueKey<String>('progress-photo-compare-before');

  /// Key of the day picker of the after side.
  static const afterKey = ValueKey<String>('progress-photo-compare-after');

  /// Key of the slider.
  static const sliderKey = ValueKey<String>('progress-photo-compare-slider');

  @override
  ConsumerState<ProgressPhotoComparePage> createState() =>
      _ProgressPhotoComparePageState();
}

class _ProgressPhotoComparePageState
    extends ConsumerState<ProgressPhotoComparePage> {
  late ProgressPhotoPose _pose =
      ProgressPhotoPose.values.asNameMap()[widget.poseName] ??
      ProgressPhotoPose.front;

  /// The picked photo ids; `null` uses the first and the newest photo.
  String? _beforeId;
  String? _afterId;
  double _split = 0.5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overview = ref.watch(
      progressPhotoOverviewProvider(ProgressScope.byName(widget.scopeName)),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.progressPhotoCompareTitle)),
      body: ListView(
        padding: responsivePagePadding(
          context,
          top: AppSpacing.md,
          bottom: AppSpacing.xl,
        ),
        children: [
          ProgressPhotoPoseChips(
            selected: _pose,
            onSelected: (pose) => setState(() {
              _pose = pose;
              _beforeId = null;
              _afterId = null;
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          ...overview.when(
            data: (overview) => _compare(context, overview),
            loading: () => const [ProgressSectionLoading()],
            error: (_, _) => [
              ProgressSectionNote(text: l10n.progressPhotosLoadFailed),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _compare(BuildContext context, ProgressPhotoOverview overview) {
    final l10n = AppLocalizations.of(context)!;
    final photos = overview.ofPose(_pose);
    if (photos.isEmpty) {
      return [ProgressSectionNote(text: l10n.progressPhotosEmpty)];
    }
    final before =
        photos.firstWhereOrNull((photo) => photo.id == _beforeId) ??
        photos.first;
    final after =
        photos.firstWhereOrNull((photo) => photo.id == _afterId) ?? photos.last;
    return [
      Row(
        spacing: AppSpacing.xs,
        children: [
          Expanded(
            child: _DayPicker(
              key: ProgressPhotoComparePage.beforeKey,
              label: l10n.progressPhotosBefore,
              photos: photos,
              selected: before,
              overview: overview,
              onSelected: (photo) => setState(() => _beforeId = photo.id),
            ),
          ),
          Expanded(
            child: _DayPicker(
              key: ProgressPhotoComparePage.afterKey,
              label: l10n.progressPhotosAfter,
              photos: photos,
              selected: after,
              overview: overview,
              onSelected: (photo) => setState(() => _afterId = photo.id),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      Stack(
        children: [
          ProgressPhotoFrame(photoId: after.id),
          Positioned.fill(
            // The outer Align loosens the constraints, so widthFactor counts.
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: ClipRect(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: _split,
                  child: ProgressPhotoFrame(photoId: before.id),
                ),
              ),
            ),
          ),
        ],
      ),
      Slider(
        key: ProgressPhotoComparePage.sliderKey,
        value: _split,
        semanticFormatterCallback: (_) => l10n.progressPhotoCompareSlider,
        onChanged: (value) => setState(() => _split = value),
      ),
    ];
  }
}

/// A kicker and a menu of the photo days of the pose.
class _DayPicker extends StatelessWidget {
  const new({
    required this.label,
    required this.photos,
    required this.selected,
    required this.overview,
    required this.onSelected,
    super.key,
  });

  final String label;
  final List<ProgressPhoto> photos;
  final ProgressPhoto selected;
  final ProgressPhotoOverview overview;
  final ValueChanged<ProgressPhoto> onSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: progressKickerStyle(context)),
        AppDropdownButtonFormField<ProgressPhoto>(
          // A new key resets the field when the pose changes the selection.
          key: ValueKey<String>(selected.id),
          initialValue: selected,
          isExpanded: true,
          items: [
            for (final photo in photos)
              DropdownMenuItem(
                value: photo,
                child: Text(DateFormat.yMMMd(locale).format(photo.day)),
              ),
          ],
          onChanged: (photo) {
            if (photo != null) {
              onSelected(photo);
            }
          },
        ),
        Text(
          progressPhotoCaption(context, selected, overview.weightKg(selected)),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
