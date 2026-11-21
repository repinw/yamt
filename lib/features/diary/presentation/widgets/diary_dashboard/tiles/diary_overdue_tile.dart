import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_overdue_plans_controller.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_caption.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_load_error.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_no_value.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_number.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_overdue_plans_hint.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The past days with plans that were never eaten, as a count or as their
/// weekdays. A tap opens the last of them, like the overdue plans hint.
const diaryOverdueTile = DiaryDashboardTile(
  spec: diaryOverdueTileSpec,
  icon: Icons.event_busy_outlined,
  label: _label,
  modes: [
    DiaryTileMode(
      id: DiaryTileModes.count,
      icon: Icons.numbers_rounded,
      label: _count,
    ),
    DiaryTileMode(
      id: DiaryTileModes.days,
      icon: Icons.calendar_view_week_outlined,
      label: _days,
    ),
  ],
  builder: _build,
);

String _label(AppLocalizations l10n) => l10n.diaryDashboardTileOverdue;

String _count(AppLocalizations l10n) => l10n.diaryDashboardOverdueModeCount;

String _days(AppLocalizations l10n) => l10n.diaryDashboardOverdueModeDays;

Widget _build(DiaryTileArgs args) => _DiaryOverdueTileBody(args: args);

class _DiaryOverdueTileBody extends ConsumerWidget {
  const new({required this.args});

  final DiaryTileArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(
      diaryCalendarControllerProvider.select((state) => state.today),
    );
    // Unlike the hint, the tile the user placed ignores a closed hint.
    final overdue = ref.watch(diaryOverduePlanDaysProvider(dateOnly(today)));
    // Never "Keine offenen Pläne" before the plans are known.
    final days = overdue.value;
    if (days == null) {
      return overdue.hasError
          ? DiaryTileLoadError(size: args.size)
          : const DiaryTileNoValue();
    }
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final small = args.size == DiaryTileSize.s1x1;

    if (days.isEmpty) {
      return small
          ? Center(
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: AppDashboard.statusIcon,
                color: colors.muted,
              ),
            )
          : Align(
              alignment: AlignmentDirectional.centerStart,
              child: DiaryTileCaption(
                l10n.diaryDashboardOverdueNone,
                icon: Icons.check_circle_outline_rounded,
                wholeOnly: true,
              ),
            );
    }

    final localeName = Localizations.localeOf(context).toLanguageTag();
    final value = args.mode == DiaryTileModes.days
        ? [
            for (final day in small ? [days.last] : days)
              calendarWeekdayLabel(day, localeName),
          ].join(' ')
        : '${days.length}';
    final number = DiaryTileNumber(value);

    return AppInkWell(
      onTap: () => openLastOverduePlanDay(ref, days),
      child: small
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xxs,
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  size: AppDashboard.captionIcon,
                  color: colors.low,
                ),
                Expanded(child: number),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.xxs,
              children: [
                DiaryTileCaption(
                  // The days' text is too long for two cells; the tile's
                  // name says what the number is.
                  args.size.columns < DiaryTileSize.s4x1.columns
                      ? l10n.diaryDashboardTileOverdue
                      : l10n.diaryDashboardOverdueDays(days.length),
                  icon: Icons.event_busy_outlined,
                  color: colors.low,
                  wholeOnly: true,
                ),
                Expanded(child: number),
              ],
            ),
    );
  }
}
