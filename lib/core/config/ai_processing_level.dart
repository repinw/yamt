enum AiProcessingLevel { minimal, low, balanced, high }

const String aiProcessingLevelStorageKey = 'preferred_ai_processing_level';

AiProcessingLevel aiProcessingLevelFromName(String? name) {
  return switch (name) {
    'minimal' => AiProcessingLevel.minimal,
    'low' => AiProcessingLevel.low,
    'high' => AiProcessingLevel.high,
    _ => AiProcessingLevel.balanced,
  };
}
