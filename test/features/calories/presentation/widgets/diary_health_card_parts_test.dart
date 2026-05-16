import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/calorie_health_connection_actions.dart';
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

  testWidgets('permission prompt uses calorie connection actions', (
    tester,
  ) async {
    final actions = _RecordingHealthActions();

    await _pumpConnectionPrompt(
      tester,
      status: _iosPermissionStatus,
      accessState: HealthDataAccessState.permissionRequired,
      actions: actions.value,
    );

    expect(find.text('ios permission body'), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(actions.requestAuthorizationCallCount, 1);
  });

  testWidgets('history and install prompts use calorie connection actions', (
    tester,
  ) async {
    final actions = _RecordingHealthActions();

    await _pumpConnectionPrompt(
      tester,
      status: _androidHistoryStatus,
      accessState: HealthDataAccessState.historyRequired,
      actions: actions.value,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    await _pumpConnectionPrompt(
      tester,
      status: _androidHistoryStatus.copyWith(
        healthConnectAvailability: HealthConnectAvailability.notInstalled,
      ),
      accessState: HealthDataAccessState.installRequired,
      actions: actions.value,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(actions.requestHistoryAuthorizationCallCount, 1);
    expect(actions.installHealthConnectCallCount, 1);
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
  required HealthConnectionStatus status,
  required HealthDataAccessState accessState,
  required CalorieHealthConnectionActions actions,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        healthConnectionServiceProvider.overrideWith(
          (ref) => FakeHealthConnectionService(status),
        ),
        calorieHealthConnectionActionsProvider.overrideWithValue(actions),
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

class _RecordingHealthActions {
  int requestAuthorizationCallCount = 0;
  int requestHistoryAuthorizationCallCount = 0;
  int installHealthConnectCallCount = 0;

  late final value = CalorieHealthConnectionActions(
    connect: _returnReadyStatus,
    requestAuthorization: () async {
      requestAuthorizationCallCount += 1;
      return _iosPermissionStatus;
    },
    requestHistoryAuthorization: () async {
      requestHistoryAuthorizationCallCount += 1;
      return _androidHistoryStatus;
    },
    installHealthConnect: () async {
      installHealthConnectCallCount += 1;
      return _androidHistoryStatus;
    },
    openHealthPermissionSettings: _returnReadyStatus,
    openAppPermissionSettings: _returnReadyStatus,
    disconnect: () async => HealthDisconnectResult.disconnected,
  );

  Future<HealthConnectionStatus> _returnReadyStatus() async {
    return _androidHistoryStatus;
  }
}
