import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_notification_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_pace_notification_listener.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The budget card menu's switch for the notification when the pace marker
/// frees a meal's kcal again; the debug build adds a button that shows it
/// in a few seconds.
class DiaryPaceNotificationSwitch extends ConsumerWidget {
  /// Creates the switch.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    DiaryPaceNotificationController controller() =>
        ref.read(diaryPaceNotificationControllerProvider.notifier);
    final blocked = ref.watch(diaryPaceNotificationBlockedProvider);
    final pace = kDebugMode ? ref.watch(diaryPaceNoticeDayProvider) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSwitchListTile(
          key: DiaryBudgetCardKeys.paceNoticeSwitch,
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.diaryBudgetMenuPaceNotice),
          // A blocked notice never shows; the system settings turn it on.
          subtitle: Text(
            blocked
                ? l10n.diaryBudgetMenuPaceNoticeBlocked
                : l10n.diaryBudgetMenuPaceNoticeHint,
          ),
          value: ref.watch(diaryPaceNotificationControllerProvider),
          onChanged: (enabled) =>
              unawaited(controller().setEnabled(enabled: enabled)),
        ),
        if (pace != null)
          TextButton.icon(
            key: DiaryBudgetCardKeys.paceNoticeDebugButton,
            icon: const Icon(Icons.bug_report_outlined),
            label: Text(l10n.diaryBudgetMenuPaceNoticeDebug),
            onPressed: () => unawaited(
              controller().debugShowSoon(pace, diaryPaceNoticeTexts(l10n)),
            ),
          ),
      ],
    );
  }
}
