import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/config/ai_processing_level.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

class AiProcessingLevelController extends Notifier<AiProcessingLevel> {
  @override
  AiProcessingLevel build() {
    final preferences = ref.read(appPreferencesProvider);
    final stored = preferences.getStringSync(aiProcessingLevelStorageKey);
    return aiProcessingLevelFromName(stored);
  }

  Future<void> setLevel(AiProcessingLevel level) async {
    if (state == level) {
      return;
    }
    state = level;
    await ref
        .read(appPreferencesProvider)
        .setString(aiProcessingLevelStorageKey, level.name);
  }
}

final aiProcessingLevelControllerProvider =
    NotifierProvider<AiProcessingLevelController, AiProcessingLevel>(
      AiProcessingLevelController.new,
    );
