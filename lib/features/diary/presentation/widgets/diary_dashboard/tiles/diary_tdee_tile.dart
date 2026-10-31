import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/features/diary/application/diary_day_tdee_provider.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_caption.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_load_error.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_no_value.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_number.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_number_body.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_number_format.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The daily TDEE the app learned, alone or against the day's goal.
const diaryTdeeTile = DiaryDashboardTile(
  spec: diaryTdeeTileSpec,
  icon: Icons.local_fire_department_outlined,
  label: _label,
  modes: [
    DiaryTileMode(
      id: DiaryTileModes.number,
      icon: Icons.pin_outlined,
      label: _number,
    ),
    DiaryTileMode(
      id: DiaryTileModes.compare,
      icon: Icons.compare_arrows_rounded,
      label: _compare,
    ),
  ],
  builder: _build,
);

String _label(AppLocalizations l10n) => l10n.diaryDashboardTileTdee;

String _number(AppLocalizations l10n) => l10n.diaryDashboardTdeeModeNumber;

String _compare(AppLocalizations l10n) => l10n.diaryDashboardTdeeModeCompare;

Widget _build(DiaryTileArgs args) => DiaryTdeeTileContent(args: args);

/// The inside of the TDEE tile.
class DiaryTdeeTileContent extends ConsumerWidget {
  /// Creates the content for [args].
  const new({required this.args, super.key});

  /// Day, size and mode of the tile.
  final DiaryTileArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const dash = DiaryTileNoValue();
    return ref
        .watch(diaryDayTdeeProvider(args.day))
        .when(
          data: (data) => switch ((args.mode, data)) {
            (
              DiaryTileModes.compare,
              (tdeeKcal: final tdee?, goalKcal: final goal?),
            ) =>
              _CompareView(size: args.size, tdeeKcal: tdee, goalKcal: goal),
            (DiaryTileModes.number, (tdeeKcal: final tdee?, goalKcal: _)) =>
              _NumberView(size: args.size, tdeeKcal: tdee),
            _ => dash,
          },
          loading: () => dash,
          error: (_, _) => DiaryTileLoadError(size: args.size),
        );
  }
}

class _NumberView extends StatelessWidget {
  const new({required this.size, required this.tdeeKcal});

  final DiaryTileSize size;
  final double tdeeKcal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = DiaryWeeklyCheckInNumberFormat(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final number = DiaryTileNumber(
      format.kcal(tdeeKcal),
      unit: size == DiaryTileSize.s1x1 ? null : l10n.caloriesUnitKcal,
    );
    if (size == DiaryTileSize.s1x1) return number;

    return DiaryTileNumberBody(
      number: number,
      captions: [
        DiaryTileCaption(
          l10n.diaryDashboardTdeePerDay,
          icon: Icons.local_fire_department_outlined,
        ),
      ],
    );
  }
}

class _CompareView extends StatelessWidget {
  const new({
    required this.size,
    required this.tdeeKcal,
    required this.goalKcal,
  });

  final DiaryTileSize size;
  final double tdeeKcal;
  final double goalKcal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = DiaryWeeklyCheckInNumberFormat(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final differenceKcal = goalKcal - tdeeKcal;
    final number = DiaryTileNumber(
      format.signedKcal(differenceKcal),
      unit: size == DiaryTileSize.s1x1 ? null : l10n.caloriesUnitKcal,
    );
    if (size == DiaryTileSize.s1x1) return number;

    final body = DiaryTileNumberBody(
      number: number,
      captions: [
        if (differenceKcal > 0)
          DiaryTileCaption(
            l10n.diaryDashboardTdeeSurplus,
            icon: Icons.trending_up_rounded,
          )
        else
          DiaryTileCaption(
            l10n.diaryDashboardTdeeDeficit,
            icon: Icons.trending_down_rounded,
          ),
      ],
    );
    if (size != DiaryTileSize.s4x1) return body;

    return Row(
      spacing: AppDashboard.tileInnerGap,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: body),
        Expanded(
          child: DiaryTileNumberBody(
            number: const SizedBox.shrink(),
            captions: [
              DiaryTileCaption(
                l10n.diaryDashboardTdeeAgainst(
                  format.kcal(goalKcal),
                  format.kcal(tdeeKcal),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
