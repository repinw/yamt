/// Pages of the calorie onboarding intro, in display order.
enum CalorieIntroPage {
  /// Welcome page with the start and login actions.
  welcome,

  /// Explains that weight follows calories in against calories out.
  calorieModel,

  /// Explains that the first expenditure number is an estimate.
  inputQuality,

  /// Explains that the estimate is corrected every week.
  followTarget,

  /// Explains the weight and burn trend.
  trend,

  /// Explains how the goal shifts the target away from the expenditure.
  goalDirection,

  /// Explains the kitchen features around tracking.
  extras,

  /// Asks for gender and birthday.
  identity,

  /// Asks for height and current weight.
  body,

  /// Asks for the target weight.
  target,

  /// Asks for the weight-change pace.
  pace,

  /// Asks for the activity level of a typical week, training included.
  activity,

  /// Asks which weekdays carry a workout.
  sport,

  /// Shows the calculated goal, asks for the start day, and finishes.
  summary;

  /// Position of this page in the chapter count, starting at 1.
  ///
  /// The welcome page is the cover and carries no chapter number.
  int? get chapterNumber => this == welcome ? null : index;

  /// Number of numbered chapters.
  static int get chapterCount => values.length - 1;

  /// The next page, or `null` on the last one.
  CalorieIntroPage? get next =>
      index + 1 < values.length ? values[index + 1] : null;
}
