import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_caption.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What a tile shows when its value could not load: the warning icon, with
/// the message when the tile spans the full width.
class DiaryTileLoadError extends StatelessWidget {
  /// Creates the error of a tile of [size].
  const new({required this.size, super.key});

  /// Size of the tile; below four columns it shows the icon alone, with the
  /// message as its label.
  final DiaryTileSize size;

  /// Whether the dashboard of [day] failed to load and has nothing to show,
  /// so a tile of its values shows this error.
  static bool watchFailed(WidgetRef ref, DateTime day) => ref.watch(
    diaryDayDashboardControllerProvider(day).select((s) => s.showError),
  );

  @override
  Widget build(BuildContext context) {
    final message = AppLocalizations.of(context)!.diaryDashboardTileLoadFailed;
    final color = FoodLabelColors.of(context).low;
    if (size.columns < DiaryTileSize.s4x1.columns) {
      return Center(
        child: Icon(
          Icons.error_outline_rounded,
          size: AppDashboard.statusIcon,
          color: color,
          semanticLabel: message,
        ),
      );
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: DiaryTileCaption(
        message,
        icon: Icons.error_outline_rounded,
        color: color,
      ),
    );
  }
}
