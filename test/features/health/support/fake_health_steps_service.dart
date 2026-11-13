import 'package:yamt/features/health/data/health_steps_service.dart';

/// Steps service that grants or declines access and answers each day with
/// [stepsOf].
class FakeHealthStepsService implements HealthStepsService {
  /// Creates the fake.
  new({this.grant = true, int? Function(DateTime day)? stepsOf})
    : stepsOf = stepsOf ?? ((_) => 8432);

  /// Whether a permission request is granted.
  final bool grant;

  /// Steps of the day that starts at the given time; may throw.
  final int? Function(DateTime day) stepsOf;

  /// Number of permission requests.
  int accessRequests = 0;

  /// Every range read so far.
  final ranges = <(DateTime, DateTime)>[];

  @override
  Future<bool> requestAccess() async {
    accessRequests += 1;
    return grant;
  }

  @override
  Future<int?> loadSteps({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    ranges.add((startInclusive, endExclusive));
    return stepsOf(startInclusive);
  }
}
