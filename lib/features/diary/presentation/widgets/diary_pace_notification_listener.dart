import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/diary/domain/diary_pace_notices.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_notice_day_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_notification_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _logName = 'DiaryPaceNotificationListener';

/// The localized texts of a pace notice.
DiaryPaceNoticeTexts diaryPaceNoticeTexts(AppLocalizations l10n) => (
  channelName: l10n.diaryPaceNoticeChannelName,
  title: l10n.diaryPaceNoticeTitle,
  body: (macro) => macro == null ? '' : l10n.diaryPaceNoticeMacro(macro.name),
);

/// Keeps the free kcal notices of today and of tomorrow's day start
/// scheduled: after every diary change, at app start, when the day moves on,
/// and when the language changes. Wraps the app below its localizations.
class DiaryPaceNotificationListener extends ConsumerStatefulWidget {
  /// Creates the listener around [child].
  const new({required this.child, super.key});

  /// The app.
  final Widget child;

  @override
  ConsumerState<DiaryPaceNotificationListener> createState() =>
      _DiaryPaceNotificationListenerState();
}

class _DiaryPaceNotificationListenerState
    extends ConsumerState<DiaryPaceNotificationListener> {
  late final ProviderSubscription<AsyncValue<DiaryPaceDay?>> _pace = ref
      .listenManual(
        diaryPaceNoticeDayProvider,
        (_, next) => _changed(next, "today's data"),
      );
  late final ProviderSubscription<AsyncValue<DiaryPaceTomorrow>> _tomorrow = ref
      .listenManual(
        diaryPaceTomorrowTargetProvider,
        (_, next) => _changed(next, "tomorrow's budget"),
      );
  // Today moves on with the diary page; on another tab only a resume does.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(diaryTodayProvider.notifier).refresh(),
    );
  }

  // The listener only hears changes: the app start and a new language
  // sync here.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  // A failed load is logged; the pending notices then stay as they are, as
  // while the data loads.
  void _changed(AsyncValue<Object?> next, String what) {
    if (next.hasError) {
      log(
        'Loading $what for the pace notices failed.',
        name: _logName,
        error: next.error,
        stackTrace: next.stackTrace,
      );
    }
    _sync();
  }

  void _sync() {
    final pace = _pace.read();
    final tomorrow = _tomorrow.read();
    unawaited(
      ref
          .read(diaryPaceNotificationControllerProvider.notifier)
          .sync(
            pace.value,
            diaryPaceNoticeTexts(AppLocalizations.of(context)!),
            tomorrowTargetKcal: tomorrow.value?.targetKcal,
            tomorrowDay: tomorrow.value?.day,
            tomorrowLoading: !tomorrow.hasValue,
            todayLoading: !pace.hasValue,
          ),
    );
  }
}
