/// What the diary does with the week of the goal run (#911).
enum WeekBalanceMode {
  /// No week card; every day stands for itself.
  off,

  /// The week card shows how the week went; every day keeps its own goal.
  show,

  /// The week card shows the week, and what past days got differently moves
  /// the budget of the days left in the run.
  carryover;

  /// Whether the budget of a day includes the carryover.
  bool get carriesOver => this == carryover;
}
