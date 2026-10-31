import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The full daily budget card as a wide tile.
const diaryBudgetTile = DiaryDashboardTile(
  spec: diaryBudgetTileSpec,
  icon: Icons.donut_large_outlined,
  label: _label,
  modes: [
    DiaryTileMode(
      id: DiaryTileModes.card,
      icon: Icons.view_agenda_outlined,
      label: _label,
    ),
  ],
  builder: _build,
);

String _label(AppLocalizations l10n) => l10n.diaryDashboardTileBudget;

Widget _build(DiaryTileArgs args) => DiaryBalanceCard(selectedDay: args.day);
