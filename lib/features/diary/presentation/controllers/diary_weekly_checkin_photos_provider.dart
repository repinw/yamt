import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_weekly_checkin_sheet_controller.dart';
import 'package:yamt/features/health/data/progress_photo_repository.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';

part 'diary_weekly_checkin_photos_provider.g.dart';

/// A photo of the check-in with the weight shown under it.
typedef DiaryWeeklyCheckInPhoto = ({ProgressPhoto photo, double? weightKg});

/// The photos of [pose] that the check-in sheet of [windowStart] and
/// [preview] (see [DiaryWeeklyCheckInSheetController]) compares: the first
/// since the goal start, a middle one, and today's. A photo shows its typed
/// weight, else the weight of its day.
@riverpod
Future<
  ({
    DiaryWeeklyCheckInPhoto? first,
    DiaryWeeklyCheckInPhoto? middle,
    DiaryWeeklyCheckInPhoto? today,
  })
>
diaryWeeklyCheckInPhotos(
  Ref ref,
  ProgressPhotoPose pose,
  DateTime today, {
  required DateTime? windowStart,
  required bool preview,
}) async {
  final sheet = diaryWeeklyCheckInSheetControllerProvider(
    windowStart: windowStart,
    preview: preview,
  );
  final plan = ref.watch(sheet).value?.plan;
  final photos = await ref.watch(progressPhotosProvider.future);
  final progress = plan?.progress;
  final milestones = progressPhotoMilestones(
    photos,
    pose: pose,
    since: progress?.startDate ?? plan?.reviewedDays.start ?? today,
    today: today,
  );
  DiaryWeeklyCheckInPhoto? withWeight(ProgressPhoto? photo) => photo == null
      ? null
      : (
          photo: photo,
          weightKg: photo.weightKg ?? progress?.weightKgOn(photo.day),
        );
  return (
    first: withWeight(milestones.first),
    middle: withWeight(milestones.middle),
    today: withWeight(milestones.today),
  );
}
