import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:yamt/core/domain/date_time_json_converter.dart';

part 'progress_photo.freezed.dart';
part 'progress_photo.g.dart';

/// The body pose of a progress photo.
enum ProgressPhotoPose {
  /// Facing the camera.
  front,

  /// One side to the camera.
  side,

  /// The back to the camera.
  back,
}

/// A body photo that shows the user's progress.
///
/// A day holds at most one photo per [pose]. [weightKg] is the weight the
/// user typed for the photo, for example for a photo from before the app; it
/// is never a weight entry. Without it the weight of [day] applies.
@freezed
abstract class ProgressPhoto with _$ProgressPhoto {
  /// Creates a photo.
  const factory({
    required String id,
    @DateTimeJsonConverter() required DateTime day,
    required ProgressPhotoPose pose,
    @JsonKey(name: 'weight_kg') double? weightKg,
  }) = _ProgressPhoto;

  /// Reads a photo document.
  factory fromJson(Map<String, dynamic> json) => _$ProgressPhotoFromJson(json);
}

/// The photos of [pose] that a check-in compares: the first from [since] on,
/// the one closest to halfway between that and [today], and today's.
///
/// `first` and `middle` are never today's photo, and `middle` is never the
/// first one, so each photo shows at most once.
({ProgressPhoto? first, ProgressPhoto? middle, ProgressPhoto? today})
progressPhotoMilestones(
  List<ProgressPhoto> photos, {
  required ProgressPhotoPose pose,
  required DateTime since,
  required DateTime today,
}) {
  final ofPose = photos
      .where((photo) => photo.pose == pose && !photo.day.isBefore(since))
      .sortedBy((photo) => photo.day);
  final todays = ofPose.where((photo) => photo.day == today).firstOrNull;
  final earlier = ofPose.where((photo) => photo.day.isBefore(today)).toList();
  final first = earlier.firstOrNull;
  if (first == null) {
    return (first: null, middle: null, today: todays);
  }
  final halfway = first.day.add(today.difference(first.day) ~/ 2);
  final middle = earlier
      .skip(1)
      .sortedBy<num>((photo) => photo.day.difference(halfway).inMinutes.abs())
      .firstOrNull;
  return (first: first, middle: middle, today: todays);
}
