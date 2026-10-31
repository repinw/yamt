import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_packing.dart';

DiaryTilePlacement _tile(String id, DiaryTileSize size) =>
    DiaryTilePlacement(id: id, size: size, mode: 'm');

void main() {
  test('tiles fill rows from the top left and a small one fills a gap', () {
    final blocks = packDiaryDashboard([
      _tile('a', DiaryTileSize.s2x2),
      _tile('b', DiaryTileSize.s4x1),
      _tile('c', DiaryTileSize.s1x1),
      _tile('d', DiaryTileSize.s2x1),
      _tile('e', DiaryTileSize.s1x1),
    ]);

    final grid = blocks.single as DiaryGridBlock;
    expect(grid.rows, 3);
    expect(
      [for (final t in grid.tiles) (t.placement.id, t.column, t.row)],
      [('a', 0, 0), ('b', 0, 2), ('c', 2, 0), ('d', 2, 1), ('e', 3, 0)],
    );
  });

  test('a wide tile splits the grid into blocks', () {
    final blocks = packDiaryDashboard([
      _tile('a', DiaryTileSize.s2x1),
      _tile('wide', DiaryTileSize.wide),
      _tile('b', DiaryTileSize.s1x1),
    ]);

    expect(blocks, hasLength(3));
    expect((blocks[0] as DiaryGridBlock).rows, 1);
    expect((blocks[1] as DiaryWideBlock).placement.id, 'wide');
    expect((blocks[2] as DiaryGridBlock).tiles.single.column, 0);
  });

  test('no tiles give no blocks', () {
    expect(packDiaryDashboard(const []), isEmpty);
  });

  test('a resize drag snaps to the closest offered size', () {
    const sizes = [DiaryTileSize.s1x1, DiaryTileSize.s2x1, DiaryTileSize.s2x2];

    expect(snapDiaryTileSize(sizes, 1.2, 0.9), DiaryTileSize.s1x1);
    expect(snapDiaryTileSize(sizes, 2.4, 1.3), DiaryTileSize.s2x1);
    expect(snapDiaryTileSize(sizes, 3.8, 2.6), DiaryTileSize.s2x2);
    expect(
      snapDiaryTileSize(const [DiaryTileSize.s4x1, DiaryTileSize.wide], 4, 2.8),
      DiaryTileSize.wide,
    );
  });
}
