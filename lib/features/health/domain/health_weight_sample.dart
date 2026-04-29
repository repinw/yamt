/// Defines health weight sample.
class HealthWeightSample {
  /// The health weight sample.
  const HealthWeightSample({
    required this.recordedAt,
    required this.weightKg,
    this.uuid,
    this.sourcePackageName,
    this.isFromThisApp = false,
  });

  /// The recorded at.
  final DateTime recordedAt;

  /// The weight kg.
  final double weightKg;

  /// Health platform record id, when available.
  final String? uuid;

  /// Source package name, when available.
  final String? sourcePackageName;

  /// Whether this sample was written by this app.
  final bool isFromThisApp;
}
