import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_catalog.dart';

void main() {
  test('the catalog has one tile per spec, in the order of the specs', () {
    expect([
      for (final tile in diaryDashboardCatalog) tile.spec,
    ], diaryDashboardTileSpecs);
  });

  test('every tile names each mode of its spec, in order', () {
    for (final tile in diaryDashboardCatalog) {
      expect(
        [for (final mode in tile.modes) mode.id],
        tile.spec.modes,
        reason: tile.id,
      );
    }
  });

  test('every spec offers its default size and has unique ids', () {
    for (final spec in diaryDashboardTileSpecs) {
      expect(spec.sizes, contains(spec.defaultSize), reason: spec.id);
      expect(spec.modes.toSet(), hasLength(spec.modes.length), reason: spec.id);
    }
    expect({
      for (final spec in diaryDashboardTileSpecs) spec.id,
    }, hasLength(diaryDashboardTileSpecs.length));
  });
}
