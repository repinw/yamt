import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/config/ai_processing_level.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_clients.dart';

class _MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 1),
        minimumFetchInterval: const Duration(seconds: 1),
      ),
    );
  });

  test('minimal processing level uses receiptocr-minimal template', () async {
    final client = StaticReceiptTemplateConfigClient(
      level: AiProcessingLevel.minimal,
    );

    expect(await client.loadTemplateId(), 'receiptocr-minimal');
  });

  test('low processing level uses receiptocr-low template', () async {
    final client = StaticReceiptTemplateConfigClient(
      level: AiProcessingLevel.low,
    );

    expect(await client.loadTemplateId(), 'receiptocr-low');
  });

  test('balanced processing level uses receiptocr-medium template', () async {
    final client = StaticReceiptTemplateConfigClient(
      level: AiProcessingLevel.balanced,
    );

    expect(await client.loadTemplateId(), 'receiptocr-medium');
  });

  test('high processing level uses receiptocr-high template', () async {
    final client = StaticReceiptTemplateConfigClient(
      level: AiProcessingLevel.high,
    );

    expect(await client.loadTemplateId(), 'receiptocr-high');
  });

  group('FirebaseReceiptTemplateConfigClient', () {
    late _MockFirebaseRemoteConfig remoteConfig;

    setUp(() {
      remoteConfig = _MockFirebaseRemoteConfig();
      when(
        () => remoteConfig.setConfigSettings(any()),
      ).thenAnswer((_) async {});
      when(() => remoteConfig.setDefaults(any())).thenAnswer((_) async {});
      when(() => remoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
    });

    test('uses level-specific remote config key for minimal', () async {
      when(
        () => remoteConfig.getString('template_id_minimal'),
      ).thenReturn('remote-template-minimal');

      final client = FirebaseReceiptTemplateConfigClient(
        remoteConfig: remoteConfig,
        level: AiProcessingLevel.minimal,
      );

      final templateId = await client.loadTemplateId();

      expect(templateId, 'remote-template-minimal');
      verify(() => remoteConfig.getString('template_id_minimal')).called(1);
    });

    test('falls back to static template when remote value is empty', () async {
      when(() => remoteConfig.getString('template_id_high')).thenReturn('   ');

      final client = FirebaseReceiptTemplateConfigClient(
        remoteConfig: remoteConfig,
        level: AiProcessingLevel.high,
      );

      final templateId = await client.loadTemplateId();

      expect(templateId, 'receiptocr-high');
      verify(() => remoteConfig.getString('template_id_high')).called(1);
    });

    test('keeps defaults available when fetchAndActivate throws', () async {
      Map<String, Object>? capturedDefaults;
      when(() => remoteConfig.setDefaults(any())).thenAnswer((
        invocation,
      ) async {
        capturedDefaults =
            invocation.positionalArguments.single as Map<String, Object>;
      });
      when(
        () => remoteConfig.fetchAndActivate(),
      ).thenThrow(Exception('network failed'));
      when(() => remoteConfig.getString(any())).thenAnswer((invocation) {
        final key = invocation.positionalArguments.single as String;
        final defaults = capturedDefaults ?? const <String, Object>{};
        return (defaults[key] as String?) ?? '';
      });

      final client = FirebaseReceiptTemplateConfigClient(
        remoteConfig: remoteConfig,
        level: AiProcessingLevel.low,
      );

      final templateId = await client.loadTemplateId();

      expect(templateId, 'receiptocr-low');
      verify(() => remoteConfig.setDefaults(any())).called(1);
      verify(() => remoteConfig.fetchAndActivate()).called(1);
    });
  });
}
