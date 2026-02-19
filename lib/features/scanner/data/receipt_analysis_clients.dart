// ignore_for_file: experimental_member_use

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_contracts.dart';

part 'receipt_analysis_clients.g.dart';

const String _receiptTemplateKey = 'template_id';
const String _fallbackReceiptTemplateId = 'receiptocr';
const String _vertexLocation = 'global';
const Duration _remoteConfigFetchTimeout = Duration(seconds: 30);
const Duration _remoteConfigProdFetchInterval = Duration(hours: 1);

@riverpod
ReceiptTemplateConfigClient receiptTemplateConfigClient(Ref ref) {
  return FirebaseReceiptTemplateConfigClient(
    remoteConfig: FirebaseRemoteConfig.instance,
  );
}

@riverpod
ReceiptTemplateModelClient receiptTemplateModelClient(Ref ref) {
  return FirebaseReceiptTemplateModelClient(
    model: FirebaseAI.vertexAI(
      location: _vertexLocation,
    ).templateGenerativeModel(),
  );
}

class FirebaseReceiptTemplateConfigClient
    implements ReceiptTemplateConfigClient {
  FirebaseReceiptTemplateConfigClient({
    required FirebaseRemoteConfig remoteConfig,
  }) : _remoteConfig = remoteConfig;

  final FirebaseRemoteConfig _remoteConfig;
  Future<void>? _initialization;

  @override
  Future<String> loadTemplateId() async {
    await _ensureInitialized();

    final templateId = _remoteConfig.getString(_receiptTemplateKey);
    if (templateId.isEmpty) {
      return _fallbackReceiptTemplateId;
    }
    return templateId;
  }

  Future<void> _ensureInitialized() {
    final initialization = _initialization;
    if (initialization != null) {
      return initialization;
    }

    final configuredInitialization = _initializeRemoteConfig();
    _initialization = configuredInitialization;
    return configuredInitialization;
  }

  Future<void> _initializeRemoteConfig() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: _remoteConfigFetchTimeout,
        minimumFetchInterval: _minimumFetchInterval(),
      ),
    );
    await _remoteConfig.setDefaults(const <String, Object>{
      _receiptTemplateKey: _fallbackReceiptTemplateId,
    });
    await _remoteConfig.fetchAndActivate();
  }

  Duration _minimumFetchInterval() {
    if (kDebugMode) {
      return Duration.zero;
    }

    return _remoteConfigProdFetchInterval;
  }
}

class FirebaseReceiptTemplateModelClient implements ReceiptTemplateModelClient {
  FirebaseReceiptTemplateModelClient({required TemplateGenerativeModel model})
    : _model = model;

  final TemplateGenerativeModel _model;

  @override
  Future<String?> generateContent({
    required String templateId,
    required Map<String, Object?> inputs,
  }) async {
    final response = await _model.generateContent(templateId, inputs: inputs);
    return response.text;
  }
}
