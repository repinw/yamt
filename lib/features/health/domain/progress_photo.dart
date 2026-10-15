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
