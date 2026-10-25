import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';

/// The photos of one day, at most one per pose.
typedef ProgressPhotoDay = ({
  DateTime day,
  Map<ProgressPhotoPose, ProgressPhoto> poses,
});

/// The photo days of one goal, newest first. `goal` is `null` for the days
/// before the first goal.
typedef ProgressPhotoGroup = ({
  ProgressGoalStart? goal,
  List<ProgressPhotoDay> days,
});

/// A before and an after photo of one pose with their weights, the weight
/// change, and the whole weeks between them.
typedef ProgressPhotoBeforeAfter = ({
  ProgressPhoto? before,
  ProgressPhoto? after,
  double? beforeKg,
  double? afterKg,
  double? changeKg,
  int? weeks,
});

/// The progress photos of a Fortschritt scope with the weight of their days.
@immutable
class ProgressPhotoOverview {
  /// Creates the overview.
  new({
    required this.photos,
    required this.goalStarts,
    required this.dayWeightsKg,
  });

  /// The photos of the scope, oldest day first.
  final List<ProgressPhoto> photos;

  /// First day of each goal, oldest first, for the grouping.
  final List<ProgressGoalStart> goalStarts;

  /// The trend weight by day, for photos without a typed weight.
  final Map<DateTime, double> dayWeightsKg;

  /// The weight shown with [photo]: the typed one, else the day's trend.
  double? weightKg(ProgressPhoto photo) =>
      photo.weightKg ?? dayWeightsKg[photo.day];

  /// The photos of [pose], oldest day first.
  List<ProgressPhoto> ofPose(ProgressPhotoPose pose) =>
      photos.where((photo) => photo.pose == pose).toList(growable: false);

  /// The default comparison of [pose]: the first photo as before and the
  /// newest as after, with the weight change and the whole weeks between
  /// them.
  ProgressPhotoBeforeAfter beforeAfter(ProgressPhotoPose pose) {
    final ofPose = this.ofPose(pose);
    final before = ofPose.firstOrNull;
    final after = ofPose.length > 1 ? ofPose.last : null;
    final beforeKg = before == null ? null : weightKg(before);
    final afterKg = after == null ? null : weightKg(after);
    return (
      before: before,
      after: after,
      beforeKg: beforeKg,
      afterKg: afterKg,
      changeKg: beforeKg == null || afterKg == null ? null : afterKg - beforeKg,
      weeks: before == null || after == null
          ? null
          : localDaysBetween(before.day, after.day) ~/ 7,
    );
  }

  /// The days of the scope grouped by goal, newest goal and day first.
  late final List<ProgressPhotoGroup> groups = _groups();

  List<ProgressPhotoGroup> _groups() {
    final byGoal = groupBy(photos, (photo) {
      return goalStarts.lastWhereOrNull(
        (start) => !photo.day.isBefore(start.day),
      );
    });
    final goals = byGoal.keys.sortedBy<DateTime>(
      (goal) => goal?.day ?? DateTime(0),
    );
    return [
      for (final goal in goals.reversed)
        (
          goal: goal,
          days: [
            for (final entry in groupBy(
              byGoal[goal]!,
              (photo) => photo.day,
            ).entries.sortedBy((entry) => entry.key).reversed)
              (
                day: entry.key,
                poses: {for (final photo in entry.value) photo.pose: photo},
              ),
          ],
        ),
    ];
  }
}
