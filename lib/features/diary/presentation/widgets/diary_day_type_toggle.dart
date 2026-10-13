import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/home_action_entry.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';
import 'package:yamt/core/widgets/home_shell_menu_scope.dart';
import 'package:yamt/features/diary/application/diary_day_type_provider.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_labels.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Day type tool in the diary top bar: the day type's emoji over its short
/// name. A tap opens the home shell's action panel at the top right with
/// training, rest, and pause; the current day type has the lime tile.
///
/// Renders nothing outside the home shell or while no calorie goal exists.
class DiaryDayTypeToggle extends ConsumerWidget {
  /// Creates the diary day type toggle.
  const new({super.key});

  /// Key of the tappable tool.
  static const buttonKey = ValueKey<String>('diary-day-type-toggle');

  /// Key of the panel entry that picks [type].
  static ValueKey<String> optionKey(DiaryDayType type) {
    return ValueKey<String>('diary-day-type-option-${type.name}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = HomeShellMenuScope.maybeOf(context);
    final selectedDay = ref.watch(diaryCalendarControllerProvider).selectedDay;
    final status = ref.watch(diaryDayTypeStatusProvider(selectedDay));
    if (scope == null || status == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;

    return HomeHeaderTool(
      key: buttonKey,
      symbol: Text(diaryDayTypeEmoji(status.type)),
      label: diaryDayTypeShortLabel(status.type, l10n),
      onPressed: () => scope.openActions(
        (ref) => _actions(ref: ref, l10n: l10n, day: selectedDay),
      ),
    );
  }

  /// The panel actions for [day], following its live day type; empty once
  /// the calorie goal is gone.
  HomeHeaderActions _actions({
    required WidgetRef ref,
    required AppLocalizations l10n,
    required DateTime day,
  }) {
    final status = ref.watch(diaryDayTypeStatusProvider(day));
    if (status == null) {
      return (sections: const <HomeActionSection>[], highlightedKey: null);
    }
    return (
      sections: [_options(ref: ref, l10n: l10n, day: day, status: status)],
      highlightedKey: optionKey(status.type),
    );
  }

  /// The day types as panel actions; each saves its type for [day] through
  /// [ref].
  HomeActionSection _options({
    required WidgetRef ref,
    required AppLocalizations l10n,
    required DateTime day,
    required DiaryDayTypeStatus status,
  }) {
    return HomeActionSection(
      title: l10n.diaryDayTypeActionsTitle,
      entries: [
        for (final type in DiaryDayType.values)
          HomeActionEntry(
            key: optionKey(type),
            symbol: Text(diaryDayTypeEmoji(type)),
            title: diaryDayTypeLabel(type, l10n),
            description: _descriptionFor(type, status, l10n),
            // Read on tap: the shell runs this builder during its build.
            onSelected: () => unawaited(
              ref.read(diaryDayTypeUpdaterProvider).select(day, type),
            ),
          ),
      ],
    );
  }

  String _descriptionFor(
    DiaryDayType type,
    DiaryDayTypeStatus status,
    AppLocalizations l10n,
  ) {
    return switch (type) {
      DiaryDayType.training when status.trainingDayKcalOffset > 0 =>
        l10n.diaryDayTypeTrainingOffsetSubtitle(
          status.trainingDayKcalOffset.toInt(),
        ),
      DiaryDayType.training => l10n.diaryDayTypeTrainingSubtitle,
      DiaryDayType.rest => l10n.diaryDayTypeRestSubtitle,
      DiaryDayType.pause => l10n.diaryDayTypePauseSubtitle,
    };
  }
}
