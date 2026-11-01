import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/diary/domain/diary_pace_notices.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_notification_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The localized texts of a pace notice.
DiaryPaceNoticeTexts diaryPaceNoticeTexts(AppLocalizations l10n) => (
  channelName: l10n.diaryPaceNoticeChannelName,
  title: (meal, kcal) => l10n.diaryPaceNoticeTitle(meal.jsonValue, kcal),
  body: (macro) => macro == null ? '' : l10n.diaryPaceNoticeMacro(macro.name),
);

/// Keeps today's free kcal notices scheduled: after every diary change, at
/// app start, when the day moves on, and when the language changes. Wraps
/// the app below its localizations.
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
  late final ProviderSubscription<DiaryPaceDay?> _pace = ref.listenManual(
    diaryPaceNoticeDayProvider,
    (_, pace) => _sync(pace),
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
    _sync(_pace.read());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _sync(DiaryPaceDay? pace) => unawaited(
    ref
        .read(diaryPaceNotificationControllerProvider.notifier)
        .sync(pace, diaryPaceNoticeTexts(AppLocalizations.of(context)!)),
  );
}
