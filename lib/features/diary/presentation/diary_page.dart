import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/diary/application/diary_provider_warmup.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_pager.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_home_shell_top_chrome.dart';
import 'package:yamt/features/health/application/'
    'health_connection_actions.dart';

/// Diary content.
class DiaryPage extends ConsumerStatefulWidget {
  /// The diary page.
  const new({super.key, this.includeHomeShellChrome = false});

  /// Key used by the shell and later design tests.
  static const pageKey = ValueKey<String>('diary-page');

  /// Whether to render the home shell's day navigator and macro strip.
  final bool includeHomeShellChrome;

  @override
  ConsumerState<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends ConsumerState<DiaryPage>
    with WidgetsBindingObserver {
  ProviderSubscription<void>? _providerWarmupSubscription;
  bool _didQueueProviderWarmup = false;

  /// Kept so a rebuild of this page does not rebuild every day page.
  late final Widget _dayPager = DiaryDayPager(
    showMacroStrip: widget.includeHomeShellChrome,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _providerWarmupSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    ref.read(diaryCalendarControllerProvider.notifier).refreshToday();
    ref.invalidate(healthConnectionStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selectedDay = ref.watch(
      diaryCalendarControllerProvider.select((state) => state.selectedDay),
    );
    final hasDashboardData = ref.watch(
      diaryDayDashboardControllerProvider(selectedDay)
          .select((state) => state.data != null),
    );
    if (hasDashboardData) {
      _queueProviderWarmup();
    }

    return ColoredBox(
      key: DiaryPage.pageKey,
      color: colors.surface,
      child: Column(
        children: [
          if (widget.includeHomeShellChrome) const DiaryHomeShellTopChrome(),
          Expanded(child: _dayPager),
        ],
      ),
    );
  }

  void _queueProviderWarmup() {
    if (_didQueueProviderWarmup) {
      return;
    }
    _didQueueProviderWarmup = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _startProviderWarmup();
    });
  }

  void _startProviderWarmup() {
    _providerWarmupSubscription ??= ref.listenManual<void>(
      diaryProviderWarmupProvider,
      _keepDiaryProviderWarm,
      fireImmediately: true,
    );
  }

  void _keepDiaryProviderWarm<T>(T? previous, T next) {}
}
