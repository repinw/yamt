import 'package:yamt/core/constants/app_sizes.dart';

/// Sizes of the diary budget card: one big kcal number, thin lines and
/// grey surfaces with one accent.
abstract final class AppBudgetCard {
  /// Inner padding of the card.
  static const double padding = 18;

  /// Top padding of the card: the toggle row's 48 high tap areas put the
  /// visible buttons 14 below the card's edge, as in the mock.
  static const double topPadding = 14 - (AppSizes.minTapTarget - dayButton) / 2;

  /// Gap between the sections of the card.
  static const double sectionGap = 16;

  /// Font size of the kcal number.
  static const double bigNumber = 68;

  /// Font size of the kcal number with more than three digits.
  static const double bigNumberLong = 52;

  /// Font size of a word in place of the kcal number, such as "Pausentag".
  static const double bigWord = 38;

  /// Letter spacing of the kcal number, as a share of its font size.
  static const double bigNumberTracking = -0.045;

  /// Line height of the kcal number.
  static const double bigNumberLineHeight = 0.9;

  /// Font size of the grams left of a macro.
  static const double macroValue = 23;

  /// Gap between the kcal column and the macro column.
  static const double columnGap = 20;

  /// Share of the width that the kcal column takes next to the macros.
  static const int kcalColumnFlex = 11;

  /// Share of the width that the macro column takes next to the kcal number.
  static const int macroColumnFlex = 10;

  /// Gap between two macro rows.
  static const double macroGap = 12;

  /// Height of the kcal line, the goal marker included.
  static const double line = 23.7;

  /// Height of the bar inside the kcal line.
  static const double lineBar = 10.1;

  /// Height of a macro line, the goal marker included.
  static const double macroLine = 16.9;

  /// Height of the bar inside a macro line.
  static const double macroLineBar = 6.8;

  /// Width of the goal marker of the kcal line.
  static const double goalMarker = 3;

  /// Width of the goal marker of a macro line.
  static const double macroGoalMarker = 2;

  /// The lines reach this share of the goal, so the overage stays visible.
  static const double lineScale = 1.2;

  /// Width of the pace marker's triangle above the kcal line.
  static const double paceMarker = 9;

  /// Width of the pace marker's stroke through the kcal line.
  static const double paceStroke = 1.5;

  /// Gap between the blocks of the parts of the day.
  static const double mealBlockGap = 4;

  /// Height of the blocks of the parts of the day.
  static const double mealSharesBar = 16;

  /// Size of a border handle of the parts of the day.
  static const double mealSharesHandle = 28;

  /// Height of a toggle chip.
  static const double chip = 34;

  /// Height of the track of the "Übrig | Gegessen" switch.
  static const double viewSwitch = 36;

  /// Gap between the track of the view switch and its pressed segment.
  static const double viewSwitchInset = 2;

  /// Line width of a toggle chip that is off.
  static const double chipOutline = 1.5;

  /// Check icon of a toggle chip that is on.
  static const double chipIcon = 15;

  /// Edge length of a day type button and a day in the week strip.
  static const double dayButton = 36;

  /// Visible gap between the training and the pause button.
  static const double dayTypeGap = 4;

  /// How far the tap area of a day type button reaches past its outer side,
  /// so each button takes a 48 wide tap with only [dayTypeGap] between them.
  static const double dayTypeHitOverhang =
      AppSizes.minTapTarget - dayButton - dayTypeGap / 2;

  /// Icon inside a day type button.
  static const double dayIcon = 18;

  /// How long a part of the details takes to fade in.
  static const Duration fadeIn = Duration(milliseconds: 260);

  /// How much later each lower part of the details starts to fade in.
  static const Duration fadeInStagger = Duration(milliseconds: 40);

  /// How far a part of the details slides down while it fades in.
  static const double fadeInOffset = 6;

  /// Corner radius of the ledger and the week strip.
  static const double boxRadius = 14;

  /// Height of one ledger row.
  static const double ledgerRow = 26;

  /// Gap between two days in the week strip.
  static const double weekDayGap = 4;

  /// Width of the ring that marks the selected day in the week strip.
  static const double weekSelectedRing = 2;
}
