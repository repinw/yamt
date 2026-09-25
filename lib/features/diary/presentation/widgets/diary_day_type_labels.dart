import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Emoji shown for a diary day type.
String diaryDayTypeEmoji(DiaryDayType type) {
  return switch (type) {
    DiaryDayType.training => '🏋️',
    DiaryDayType.rest => '🛋️',
    DiaryDayType.pause => '⏸️',
  };
}

/// Localized name of a diary day type.
String diaryDayTypeLabel(DiaryDayType type, AppLocalizations l10n) {
  return switch (type) {
    DiaryDayType.training => l10n.diaryDayTypeTraining,
    DiaryDayType.rest => l10n.diaryDayTypeRest,
    DiaryDayType.pause => l10n.diaryDayTypePause,
  };
}

/// Short localized name of a diary day type, for the top bar chip.
String diaryDayTypeShortLabel(DiaryDayType type, AppLocalizations l10n) {
  return switch (type) {
    DiaryDayType.training => l10n.diaryDayTypeTrainingShort,
    DiaryDayType.rest => l10n.diaryDayTypeRestShort,
    DiaryDayType.pause => l10n.diaryDayTypePauseShort,
  };
}
