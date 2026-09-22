import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_home_widget_summary_provider.dart';
import 'package:yamt/features/home_widget/application/home_widget_snapshot_mapper.dart';
import 'package:yamt/features/home_widget/data/home_widget_plugin_bridge.dart';
import 'package:yamt/features/home_widget/domain/home_widget_exceptions.dart';
import 'package:yamt/features/home_widget/presentation/controllers/'
    'home_widget_verbose_mode_controller.dart';

part 'home_widget_sync_controller.g.dart';

const _logName = 'HomeWidgetSyncController';

/// Keeps the home-screen widget's saved snapshot in sync with today's diary
/// summary and the silent/verbose preference.
///
/// Auto-dispose like the providers it listens to. `lib/app.dart` holds a
/// listener on it for the app's lifetime: that keeps it and its `ref.listen`
/// subscriptions active. Without an active listener Riverpod pauses those
/// subscriptions and the diary summary is disposed.
@riverpod
class HomeWidgetSyncController extends _$HomeWidgetSyncController {
  @override
  void build() {
    ref
      ..listen(
        diaryHomeWidgetSummaryProvider,
        (_, _) => unawaited(_sync()),
        fireImmediately: true,
      )
      ..listen(
        homeWidgetVerboseModeControllerProvider,
        (_, _) => unawaited(_sync()),
      );
  }

  Future<void> _sync() async {
    final snapshot = buildHomeWidgetSnapshot(
      summary: ref.read(diaryHomeWidgetSummaryProvider),
      verbose: ref.read(homeWidgetVerboseModeControllerProvider),
      now: ref.read(clockProvider)(),
    );
    if (snapshot == null) {
      // No diary data loaded yet: keep the widget's last synced snapshot
      // instead of writing zeros over it.
      return;
    }
    try {
      await ref
          .read(homeWidgetPluginBridgeProvider)
          .saveSnapshot(jsonEncode(snapshot.toJson()));
    } on HomeWidgetException catch (error, stackTrace) {
      // The widget keeps showing its last snapshot; the next change retries.
      log(
        'Home widget sync failed',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
