import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

part 'ai_processing_level_controller.g.dart';

enum AiProcessingLevel { low, balanced, high }

@Riverpod(keepAlive: true)
class AiProcessingLevelController extends _$AiProcessingLevelController {
  static const String _storageKey = 'preferred_ai_processing_level';

  @override
  AiProcessingLevel build() {
    final preferences = ref.read(appPreferencesProvider);
    final stored = preferences.getStringSync(_storageKey);
    if (stored != null) {
      return _fromName(stored);
    }

    unawaited(_loadStoredValue());
    return AiProcessingLevel.balanced;
  }

  Future<void> setLevel(AiProcessingLevel level) async {
    if (state == level) {
      return;
    }
    state = level;
    await ref.read(appPreferencesProvider).setString(_storageKey, level.name);
  }

  Future<void> _loadStoredValue() async {
    final stored = await ref
        .read(appPreferencesProvider)
        .getString(_storageKey);
    if (!ref.mounted || stored == null) {
      return;
    }
    state = _fromName(stored);
  }

  AiProcessingLevel _fromName(String name) {
    return switch (name) {
      'low' => AiProcessingLevel.low,
      'high' => AiProcessingLevel.high,
      _ => AiProcessingLevel.balanced,
    };
  }
}
