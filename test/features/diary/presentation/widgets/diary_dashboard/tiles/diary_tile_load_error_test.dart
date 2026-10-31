import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_grid_block.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_weight_tile.dart';
import 'package:yamt/features/health/data/health_weight_sample_repository.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../calories/support/fake_calories_repositories.dart';

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('de'));

final _now = DateTime(2026, 10, 31, 12);
final _today = DateTime(2026, 10, 31);

/// The grid of a phone 390 px wide, less the page's side padding.
final _metrics = DiaryDashboardMetrics.of(358, TextScaler.noScaling);

/// The cloud copies of the Health weights, whose read fails.
class _FailingWeightSamples extends Fake
    implements HealthWeightSampleRepository {
  @override
  Stream<List<HealthWeightSample>> watchSamples() async* {
    await Future<void>.delayed(Duration.zero);
    throw StateError('read failed');
  }
}

/// Pumps the weight tile of [size] inside the frame of its tile, with
/// weights that fail to load.
Future<void> _pump(WidgetTester tester, DiaryTileSize size) async {
  await tester.pumpWidget(
    ProviderScope(
      // The error itself, not Riverpod's retries.
      retry: (_, _) => null,
      overrides: [
        clockProvider.overrideWithValue(() => _now),
        manualHealthWeightRepositoryProvider.overrideWithValue(
          FakeManualHealthWeightRepository([]),
        ),
        healthWeightSampleRepositoryProvider.overrideWithValue(
          _FailingWeightSamples(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width:
                  _metrics.width(size.columns) - 2 * AppDashboard.tilePadding,
              height:
                  _metrics.height(size.rows!) - 2 * AppDashboard.tilePadding,
              child: DiaryWeightTileContent(
                args: DiaryTileArgs(
                  day: _today,
                  size: size,
                  mode: DiaryTileModes.number,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final message = _l10n.diaryDashboardTileLoadFailed;
  final errorIcon = find.byIcon(Icons.error_outline_rounded);

  for (final (size, name) in [
    (DiaryTileSize.s2x1, '2×1'),
    (DiaryTileSize.s2x2, '2×2'),
  ]) {
    testWidgets('$name shows the error icon with the message as its label', (
      tester,
    ) async {
      await _pump(tester, size);

      expect(find.text(message), findsNothing);
      expect(errorIcon, findsOneWidget);
      expect(tester.widget<Icon>(errorIcon).semanticLabel, message);
      // The tile's add button reads it after its own label.
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(message))),
        findsOneWidget,
      );
    });
  }

  testWidgets('4×1 shows the error icon with the message', (tester) async {
    await _pump(tester, DiaryTileSize.s4x1);

    expect(errorIcon, findsOneWidget);
    expect(find.text(message), findsOneWidget);
  });
}
