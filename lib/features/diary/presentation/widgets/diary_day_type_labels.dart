import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Emoji shown for a diary day type.
String diaryDayTypeEmoji(DiaryDayType type) {
  return switch (type) {
    DiaryDayType.training => '🏋️',
    DiaryDayType.normal => '🛋️',
    DiaryDayType.pause => '⏸️',
  };
}

/// Localized name of a diary day type.
String diaryDayTypeLabel(DiaryDayType type, AppLocalizations l10n) {
  return switch (type) {
    DiaryDayType.training => l10n.diaryDayTypeTraining,
    DiaryDayType.normal => l10n.diaryDayTypeNormal,
    DiaryDayType.pause => l10n.diaryDayTypePause,
  };
}

/// Short name of a diary day type, for the pressed day type button.
String diaryDayTypeShortLabel(DiaryDayType type, AppLocalizations l10n) {
  return switch (type) {
    DiaryDayType.training => l10n.diaryDayTypeTrainingShort,
    DiaryDayType.normal => l10n.diaryDayTypeNormalShort,
    DiaryDayType.pause => l10n.diaryDayTypePauseShort,
  };
}
