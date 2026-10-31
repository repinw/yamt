import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';

const _budget = DiaryTileSpec(
  id: 'budget',
  sizes: [DiaryTileSize.wide],
  defaultSize: DiaryTileSize.wide,
  modes: ['card'],
);
const _kcal = DiaryTileSpec(
  id: 'kcal',
  sizes: [DiaryTileSize.s1x1, DiaryTileSize.s2x1, DiaryTileSize.s2x2],
  defaultSize: DiaryTileSize.s2x1,
  modes: ['number', 'ring'],
);
const _weight = DiaryTileSpec(
  id: 'weight',
  sizes: [DiaryTileSize.s2x1],
  defaultSize: DiaryTileSize.s2x1,
  modes: ['sparkline'],
);
const _overdue = DiaryTileSpec(
  id: 'overdue',
  sizes: [DiaryTileSize.s2x1],
  defaultSize: DiaryTileSize.s2x1,
  modes: ['count'],
  visibleByDefault: false,
);

const List<DiaryTileSpec> _catalog = [_budget, _kcal, _weight, _overdue];

List<String> _ids(DiaryDashboardLayout layout) => [
  for (final t in layout.tiles) t.id,
];

void main() {
  test('the initial layout shows the default tiles in catalog order', () {
    final layout = DiaryDashboardLayout.initial(_catalog);

    expect(_ids(layout), ['budget', 'kcal', 'weight']);
    expect(layout.hidden, ['overdue']);
    expect(layout.tiles[1], DiaryTilePlacement.of(_kcal));
  });

  test('a new tile sorts in after the closest tile before it', () {
    const saved = DiaryDashboardLayout(
      tiles: [
        DiaryTilePlacement(
          id: 'weight',
          size: DiaryTileSize.s2x1,
          mode: 'sparkline',
        ),
        DiaryTilePlacement(
          id: 'budget',
          size: DiaryTileSize.wide,
          mode: 'card',
        ),
      ],
      hidden: ['overdue'],
    );

    expect(_ids(saved.resolve(_catalog)), ['weight', 'budget', 'kcal']);
  });

  test('a new tile with no known tile before it goes first', () {
    const saved = DiaryDashboardLayout(
      tiles: [
        DiaryTilePlacement(
          id: 'weight',
          size: DiaryTileSize.s2x1,
          mode: 'sparkline',
        ),
      ],
      hidden: ['kcal'],
    );

    expect(_ids(saved.resolve(_catalog)), ['budget', 'weight']);
    expect(saved.resolve(_catalog).hidden, ['kcal', 'overdue']);
  });

  test('resolve drops unknown and doubled tiles and fixes sizes and modes', () {
    const saved = DiaryDashboardLayout(
      tiles: [
        DiaryTilePlacement(id: 'gone', size: DiaryTileSize.s1x1, mode: 'x'),
        DiaryTilePlacement(id: 'kcal', size: DiaryTileSize.s4x2, mode: 'bar'),
        DiaryTilePlacement(id: 'kcal', size: DiaryTileSize.s1x1, mode: 'ring'),
      ],
      hidden: ['gone', 'budget', 'weight', 'overdue', 'kcal'],
    );

    final resolved = saved.resolve(_catalog);

    expect(resolved.tiles, [DiaryTilePlacement.of(_kcal)]);
    expect(resolved.hidden, ['budget', 'weight', 'overdue']);
  });

  test('move, hide and show change the order and the hidden tiles', () {
    final layout = DiaryDashboardLayout.initial(_catalog);

    expect(_ids(layout.move('weight', 0)), ['weight', 'budget', 'kcal']);
    expect(_ids(layout.move('budget', 2)), ['kcal', 'weight', 'budget']);
    expect(_ids(layout.move('budget', 9)), ['kcal', 'weight', 'budget']);

    final hidden = layout.hide('kcal');
    expect(_ids(hidden), ['budget', 'weight']);
    expect(hidden.hidden, ['overdue', 'kcal']);

    final shown = hidden.show(_overdue);
    expect(_ids(shown), ['budget', 'weight', 'overdue']);
    expect(shown.hidden, ['kcal']);
  });

  test('update replaces the placement of one tile', () {
    final layout = DiaryDashboardLayout.initial(_catalog);
    final ring = layout.tiles[1].copyWith(mode: 'ring');

    expect(layout.update(ring).tiles[1], ring);
    expect(layout.update(ring).tiles[0], layout.tiles[0]);
  });

  test('json round trip keeps the layout', () {
    final layout = DiaryDashboardLayout.initial(_catalog).hide('weight');

    expect(DiaryDashboardLayout.fromJson(layout.toJson()), layout);
  });

  test('json with an unknown size fails', () {
    expect(
      () => DiaryDashboardLayout.fromJson(const {
        'tiles': [
          {'id': 'kcal', 'size': 's9x9', 'mode': 'number'},
        ],
        'hidden': <String>[],
      }),
      throwsA(isA<Exception>()),
    );
  });
}
