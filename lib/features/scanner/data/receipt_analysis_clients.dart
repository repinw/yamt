// ignore_for_file: experimental_member_use

import 'dart:developer' as developer;

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/config/ai_processing_level.dart';
import 'package:yamt/core/config/ai_processing_level_controller.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_contracts.dart';

part 'receipt_analysis_clients.g.dart';

const String _minimalReceiptTemplateId = 'receiptocr-minimal';
const String _lowReceiptTemplateId = 'receiptocr-low';
const String _balancedReceiptTemplateId = 'receiptocr-medium';
const String _highReceiptTemplateId = 'receiptocr-high';
const String _minimalReceiptTemplateKey = 'template_id_minimal';
const String _lowReceiptTemplateKey = 'template_id_low';
const String _balancedReceiptTemplateKey = 'template_id_medium';
const String _highReceiptTemplateKey = 'template_id_high';
const String _vertexLocation = 'global';
const Duration _remoteConfigFetchTimeout = Duration(seconds: 30);
const Duration _remoteConfigProdFetchInterval = Duration(hours: 1);

@riverpod
ReceiptTemplateConfigClient receiptTemplateConfigClient(Ref ref) {
  final level = ref.watch(aiProcessingLevelControllerProvider);
  return FirebaseReceiptTemplateConfigClient(
    remoteConfig: FirebaseRemoteConfig.instance,
    level: level,
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

class StaticReceiptTemplateConfigClient implements ReceiptTemplateConfigClient {
  StaticReceiptTemplateConfigClient({required AiProcessingLevel level})
    : _level = level;

  final AiProcessingLevel _level;

  @override
  Future<String> loadTemplateId() async {
    return switch (_level) {
      AiProcessingLevel.minimal => _minimalReceiptTemplateId,
      AiProcessingLevel.low => _lowReceiptTemplateId,
      AiProcessingLevel.balanced => _balancedReceiptTemplateId,
      AiProcessingLevel.high => _highReceiptTemplateId,
    };
  }
}

class FirebaseReceiptTemplateConfigClient
    implements ReceiptTemplateConfigClient {
  FirebaseReceiptTemplateConfigClient({
    required FirebaseRemoteConfig remoteConfig,
    required AiProcessingLevel level,
  }) : _remoteConfig = remoteConfig,
       _fallbackClient = StaticReceiptTemplateConfigClient(level: level),
       _templateKey = _templateKeyForLevel(level);

  final FirebaseRemoteConfig _remoteConfig;
  final StaticReceiptTemplateConfigClient _fallbackClient;
  final String _templateKey;
  Future<void>? _initialization;

  @override
  Future<String> loadTemplateId() async {
    await _ensureInitialized();

    final levelTemplate = _remoteConfig.getString(_templateKey).trim();
    if (levelTemplate.isNotEmpty) {
      return levelTemplate;
    }

    return _fallbackClient.loadTemplateId();
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
      _minimalReceiptTemplateKey: _minimalReceiptTemplateId,
      _lowReceiptTemplateKey: _lowReceiptTemplateId,
      _balancedReceiptTemplateKey: _balancedReceiptTemplateId,
      _highReceiptTemplateKey: _highReceiptTemplateId,
    });
    // Keep local defaults if fetch fails, so template resolution remains stable.
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (error, stackTrace) {
      developer.log(
        'Remote Config fetch failed, using template defaults',
        name: 'ReceiptTemplateConfigClient',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Duration _minimumFetchInterval() {
    if (kDebugMode) {
      return Duration.zero;
    }

    return _remoteConfigProdFetchInterval;
  }

  static String _templateKeyForLevel(AiProcessingLevel level) {
    return switch (level) {
      AiProcessingLevel.minimal => _minimalReceiptTemplateKey,
      AiProcessingLevel.low => _lowReceiptTemplateKey,
      AiProcessingLevel.balanced => _balancedReceiptTemplateKey,
      AiProcessingLevel.high => _highReceiptTemplateKey,
    };
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
