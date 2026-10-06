import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'last_planned_day_provider.g.dart';

/// A saved plan's day. The count tells two plans on the same day apart.
typedef PlannedDay = ({DateTime day, int count});

/// The day of the plan saved last, so the diary can open that day.
@Riverpod(keepAlive: true)
class LastPlannedDay extends _$LastPlannedDay {
  @override
  PlannedDay? build() => null;

  /// Tells listeners that a new plan was saved on [day].
  void planned(DateTime day) {
    state = (day: day, count: (state?.count ?? 0) + 1);
  }
}
