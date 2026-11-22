import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';

/// Ids of the diary dashboard tiles, saved in the layout.
abstract final class DiaryTileIds {
  /// The budget card.
  static const budget = 'budget';

  /// Calories eaten against the day's goal.
  static const kcal = 'kcal';

  /// Protein, carbs and fat against their goals.
  static const macros = 'macros';

  /// The weight trend.
  static const weight = 'weight';

  /// The daily energy expenditure the app learned.
  static const tdee = 'tdee';

  /// Training, normal or pause day.
  static const dayType = 'daytype';

  /// Calories per meal.
  static const meals = 'meals';

  /// Past days with plans that were never eaten.
  static const overdue = 'overdue';
}

/// Ids of the display modes of the diary dashboard tiles, saved in the
/// layout. Tiles that show the same kind of view share an id.
abstract final class DiaryTileModes {
  /// The budget card as it is.
  static const card = 'card';

  /// One number.
  static const number = 'number';

  /// A number per value.
  static const numbers = 'numbers';

  /// One progress bar.
  static const bar = 'bar';

  /// A bar per value.
  static const bars = 'bars';

  /// One progress ring.
  static const ring = 'ring';

  /// A progress ring per value.
  static const rings = 'rings';

  /// The last values as a line.
  static const sparkline = 'sparkline';

  /// The value next to the goal it is compared with.
  static const compare = 'compare';

  /// An icon for the value.
  static const icon = 'icon';

  /// Buttons that switch the value.
  static const toggle = 'toggle';

  /// One line per item.
  static const list = 'list';

  /// How many there are.
  static const count = 'count';

  /// The weekdays.
  static const days = 'days';
}

/// Every tile the diary dashboard offers, in the order of the default
/// layout. A tile added later sorts itself in after the tile before it here.
const diaryDashboardTileSpecs = <DiaryTileSpec>[
  diaryBudgetTileSpec,
  diaryKcalTileSpec,
  diaryMacrosTileSpec,
  diaryWeightTileSpec,
  diaryTdeeTileSpec,
  diaryDayTypeTileSpec,
  diaryMealsTileSpec,
  diaryOverdueTileSpec,
];

/// The budget card, as one wide tile.
const diaryBudgetTileSpec = DiaryTileSpec(
  id: DiaryTileIds.budget,
  sizes: [DiaryTileSize.wide],
  defaultSize: DiaryTileSize.wide,
  modes: [DiaryTileModes.card],
);

/// Calories left or eaten of the day.
const diaryKcalTileSpec = DiaryTileSpec(
  id: DiaryTileIds.kcal,
  sizes: [
    DiaryTileSize.s1x1,
    DiaryTileSize.s2x1,
    DiaryTileSize.s2x2,
    DiaryTileSize.s4x1,
  ],
  defaultSize: DiaryTileSize.s2x1,
  modes: [DiaryTileModes.number, DiaryTileModes.bar, DiaryTileModes.ring],
  visibleByDefault: false,
);

/// Protein, carbs and fat of the day.
const diaryMacrosTileSpec = DiaryTileSpec(
  id: DiaryTileIds.macros,
  sizes: [
    DiaryTileSize.s2x1,
    DiaryTileSize.s2x2,
    DiaryTileSize.s4x1,
    DiaryTileSize.s4x2,
  ],
  defaultSize: DiaryTileSize.s4x1,
  modes: [DiaryTileModes.bars, DiaryTileModes.rings, DiaryTileModes.numbers],
  visibleByDefault: false,
);

/// The weight trend up to the day.
const diaryWeightTileSpec = DiaryTileSpec(
  id: DiaryTileIds.weight,
  sizes: [
    DiaryTileSize.s1x1,
    DiaryTileSize.s2x1,
    DiaryTileSize.s2x2,
    DiaryTileSize.s4x1,
  ],
  defaultSize: DiaryTileSize.s2x1,
  modes: [DiaryTileModes.number, DiaryTileModes.sparkline],
  visibleByDefault: false,
);

/// The daily energy expenditure the app learned.
const diaryTdeeTileSpec = DiaryTileSpec(
  id: DiaryTileIds.tdee,
  sizes: [DiaryTileSize.s1x1, DiaryTileSize.s2x1, DiaryTileSize.s4x1],
  defaultSize: DiaryTileSize.s2x1,
  modes: [DiaryTileModes.number, DiaryTileModes.compare],
  visibleByDefault: false,
);

/// Training, normal or pause day.
const diaryDayTypeTileSpec = DiaryTileSpec(
  id: DiaryTileIds.dayType,
  sizes: [DiaryTileSize.s1x1, DiaryTileSize.s2x1],
  defaultSize: DiaryTileSize.s2x1,
  modes: [DiaryTileModes.icon, DiaryTileModes.toggle],
  visibleByDefault: false,
);

/// Calories per meal of the day.
const diaryMealsTileSpec = DiaryTileSpec(
  id: DiaryTileIds.meals,
  sizes: [
    DiaryTileSize.s2x1,
    DiaryTileSize.s2x2,
    DiaryTileSize.s4x1,
    DiaryTileSize.s4x2,
  ],
  defaultSize: DiaryTileSize.s4x1,
  modes: [DiaryTileModes.bars, DiaryTileModes.list],
  visibleByDefault: false,
);

/// Past days with plans that were never eaten.
const diaryOverdueTileSpec = DiaryTileSpec(
  id: DiaryTileIds.overdue,
  sizes: [DiaryTileSize.s1x1, DiaryTileSize.s2x1, DiaryTileSize.s4x1],
  defaultSize: DiaryTileSize.s2x1,
  modes: [DiaryTileModes.count, DiaryTileModes.days],
  visibleByDefault: false,
);
