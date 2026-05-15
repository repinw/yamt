import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_loaded_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_loading.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_shell.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'diary_balance_card.g.dart';

/// Ticker period for minute-sensitive balance UI updates.
@riverpod
Duration diaryBalanceTickerDuration(Ref ref) => diaryBalanceTickerPeriod;

/// Optional observer for balance ticker tests.
@riverpod
VoidCallback? diaryBalanceTickerObserver(Ref ref) => null;

/// Weekly calorie balance card for the diary page.
class DiaryBalanceCard extends ConsumerStatefulWidget {
  /// Creates the diary balance card.
  const DiaryBalanceCard({
    required this.selectedDay,
    super.key,
  });

  /// The selected diary day.
  final DateTime selectedDay;

  @override
  ConsumerState<DiaryBalanceCard> createState() => _DiaryBalanceCardState();
}

class _DiaryBalanceCardState extends ConsumerState<DiaryBalanceCard>
    with
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin<DiaryBalanceCard> {
  DiaryBalanceSource? _lastSource;
  Timer? _ticker;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTicker();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTicker();
      if (mounted) {
        setState(() {});
      }
      return;
    }
    _stopTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final normalizedSelectedDay = normalizeDiaryDay(widget.selectedDay);
    final sourceState = ref.watch(
      diaryBalanceSourceProvider(normalizedSelectedDay),
    );
    final source = sourceState.value;

    if (source != null) {
      _lastSource = source;
      return _buildLoaded(source);
    }

    final lastSource = _lastSource;
    if (!sourceState.hasError && lastSource != null) {
      return _buildLoaded(lastSource);
    }

    if (sourceState.hasError) {
      final l10n = AppLocalizations.of(context)!;
      return DiaryBalanceShell(
        child: MetricErrorRetryContent(
          message: l10n.diaryBalanceLoadFailed,
          retryLabel: l10n.caloriesRetryAction,
          retryButtonKey: DiaryBalanceCardKeys.retryButton,
          onRetry: () => _retryBalance(normalizedSelectedDay),
        ),
      );
    }

    return const DiaryBalanceLoading();
  }

  void _retryBalance(DateTime normalizedSelectedDay) {
    ref.read(diaryBalanceActionsProvider).refreshBalance(normalizedSelectedDay);
  }

  Widget _buildLoaded(DiaryBalanceSource source) {
    return DiaryBalanceLoadedCard(
      data: source.resolve(now: DateTime.now()),
      onUnmarkHeartDay: _unmarkHeartDay,
    );
  }

  void _unmarkHeartDay(DateTime day) {
    unawaited(
      ref.read(diaryBalanceActionsProvider).unmarkHeartDay(day),
    );
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(ref.read(diaryBalanceTickerDurationProvider), (
      _,
    ) {
      ref.read(diaryBalanceTickerObserverProvider)?.call();
      if (!mounted) {
        _stopTicker();
        return;
      }
      setState(() {});
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}
