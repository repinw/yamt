import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'diary_health_card_parts.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../support/fake_calories_repositories.dart';

const _iosPermissionStatus = HealthConnectionStatus(
  platform: HealthPlatform.ios,
  healthConnectAvailability: HealthConnectAvailability.notApplicable,
  permissionState: HealthPermissionState.notGranted,
  historyAccess: HealthHistoryAccess.notApplicable,
);

const _androidHistoryStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.notGranted,
);

void main() {
  testWidgets('frame renders title subtitle and child', (tester) async {
    await _pumpPlainWidget(
      tester,
      const DiaryHealthCardFrame(
        title: 'Health title',
        subtitle: 'Health subtitle',
        child: Text('Health child'),
      ),
    );

    expect(find.text('Health title'), findsOneWidget);
    expect(find.text('Health subtitle'), findsOneWidget);
    expect(find.text('Health child'), findsOneWidget);
  });

  testWidgets('access prompt shows busy unsupported state without action', (
    tester,
  ) async {
    await _pumpPlainWidget(
      tester,
      const DiaryHealthAccessPrompt(
        accessState: HealthDataAccessState.unsupported,
        isBusy: true,
        permissionBody: 'permission body',
        historyBody: 'history body',
        installBody: 'install body',
        unsupportedBody: 'unsupported body',
        onGrantAccess: _noopAction,
        onGrantHistoryAccess: _noopAction,
        onInstallHealthConnect: _noopAction,
      ),
    );

    expect(find.text('unsupported body'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('permission prompt uses Health controller action', (
    tester,
  ) async {
    final healthService = FakeHealthConnectionService(_iosPermissionStatus);

    await _pumpConnectionPrompt(
      tester,
      healthService: healthService,
      accessState: HealthDataAccessState.permissionRequired,
    );

    expect(find.text('ios permission body'), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(healthService.requestAuthorizationCallCount, 1);
  });

  testWidgets('history and install prompts use Health controller actions', (
    tester,
  ) async {
    final historyHealthService = FakeHealthConnectionService(
      _androidHistoryStatus,
    );

    await _pumpConnectionPrompt(
      tester,
      healthService: historyHealthService,
      accessState: HealthDataAccessState.historyRequired,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final installHealthService = FakeHealthConnectionService(
      _androidHistoryStatus.copyWith(
        healthConnectAvailability: HealthConnectAvailability.notInstalled,
      ),
    );
    await _pumpConnectionPrompt(
      tester,
      healthService: installHealthService,
      accessState: HealthDataAccessState.installRequired,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(historyHealthService.requestHistoryAuthorizationCallCount, 1);
    expect(installHealthService.installHealthConnectCallCount, 1);
  });
}

Future<void> _pumpPlainWidget(
  WidgetTester tester,
  Widget child,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}

Future<void> _pumpConnectionPrompt(
  WidgetTester tester, {
  required FakeHealthConnectionService healthService,
  required HealthDataAccessState accessState,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        healthConnectionServiceProvider.overrideWith(
          (ref) => healthService,
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: DiaryHealthConnectionPrompt(
            accessState: accessState,
            androidPermissionBody: 'android permission body',
            iosPermissionBody: 'ios permission body',
            historyBody: 'history body',
            installBody: 'install body',
            unsupportedBody: 'unsupported body',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _noopAction() async {}
