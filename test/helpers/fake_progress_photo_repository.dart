import 'dart:async';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/features/health/data/progress_photo_repository.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';

/// In-memory progress photos with a picker that hands out [pickedImage].
class FakeProgressPhotoRepository extends Fake
    implements ProgressPhotoRepository {
  /// Creates the fake with the stored [photos].
  new({List<ProgressPhoto> photos = const <ProgressPhoto>[], this.pickedImage})
    : _photos = <ProgressPhoto>[...photos];

  final List<ProgressPhoto> _photos;
  final _changes = StreamController<List<ProgressPhoto>>.broadcast();

  /// The image the picker returns; `null` acts like a cancelled pick.
  Uint8List? pickedImage;

  /// The error the photo stream fails with, if any.
  Exception? watchError;

  /// The error the next save throws, if any.
  Exception? saveError;

  /// The sources the picker was opened with.
  final pickedSources = <ImageSource>[];

  /// The stored photos.
  List<ProgressPhoto> get photos => List.unmodifiable(_photos);

  @override
  Stream<List<ProgressPhoto>> watchPhotos() async* {
    if (watchError case final error?) {
      throw error;
    }
    yield photos;
    yield* _changes.stream;
  }

  @override
  Future<Uint8List?> pickPhoto(ImageSource source) async {
    pickedSources.add(source);
    return pickedImage;
  }

  @override
  Future<ProgressPhoto> savePhoto({
    required DateTime day,
    required ProgressPhotoPose pose,
    required Uint8List imageBytes,
    double? weightKg,
  }) async {
    await Future<void>.delayed(Duration.zero);
    if (saveError case final error?) {
      throw error;
    }
    final photo = ProgressPhoto(
      id: 'photo-${_photos.length + 1}',
      day: day,
      pose: pose,
      weightKg: weightKg,
    );
    _photos
      ..removeWhere((old) => old.day == day && old.pose == pose)
      ..add(photo);
    _changes.add(photos);
    return photo;
  }

  /// Closes the change stream.
  Future<void> dispose() => _changes.close();
}
