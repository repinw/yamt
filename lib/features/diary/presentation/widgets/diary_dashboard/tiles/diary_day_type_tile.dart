import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/application/diary_day_type_provider.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/diary_day_type_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_day_type_buttons.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_tile_parts.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_labels.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The day type of the selected day: normal, training, or pause.
const diaryDayTypeTile = DiaryDashboardTile(
  id: 'daytype',
  icon: Icons.fitness_center_rounded,
  label: _label,
  sizes: [DiaryTileSize.s1x1, DiaryTileSize.s2x1],
  defaultSize: DiaryTileSize.s2x1,
  modes: [
    DiaryTileMode(id: 'icon', icon: Icons.label_outline, label: _iconLabel),
    DiaryTileMode(
      id: 'toggle',
      icon: Icons.toggle_on_outlined,
      label: _toggleLabel,
    ),
  ],
  builder: _build,
  visibleByDefault: false,
);

String _label(AppLocalizations l10n) => l10n.diaryDashboardTileDayType;

String _iconLabel(AppLocalizations l10n) => l10n.diaryDashboardModeIcon;

String _toggleLabel(AppLocalizations l10n) => l10n.diaryDashboardModeToggle;

Widget _build(DiaryTileArgs args) => DiaryDayTypeTile(args: args);

/// Inside of the day type tile.
class DiaryDayTypeTile extends ConsumerWidget {
  /// Creates the tile for [args].
  const new({required this.args, super.key});

  /// Day, size, and mode of the tile.
  final DiaryTileArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(diaryDayTypeStatusProvider(args.day))?.type;
    if (type == null) {
      return DiaryTileNumber(
        '–',
        color: FoodLabelColors.of(context).muted,
        alignment: AlignmentDirectional.center,
      );
    }
    final isSmall = args.size == DiaryTileSize.s1x1;
    void select(DiaryDayType next) => unawaited(
      selectDiaryDayTypeFlow(context, ref, day: args.day, type: next),
    );

    if (args.mode == 'toggle') {
      if (isSmall) {
        return _CurrentTypeButton(
          type: type,
          onTap: () => select(
            type == DiaryDayType.training
                ? DiaryDayType.normal
                : DiaryDayType.training,
          ),
        );
      }
      return Row(
        spacing: AppSpacing.xs,
        children: [
          for (final button in const [
            DiaryDayType.training,
            DiaryDayType.pause,
          ])
            Expanded(
              child: _TypeButton(
                type: button,
                selected: type == button,
                // Like the card's toggle row: a pressed button sets back
                // to a normal day.
                onTap: () =>
                    select(type == button ? DiaryDayType.normal : button),
              ),
            ),
        ],
      );
    }
    return _TypeIcon(type: type, showName: !isSmall);
  }
}

/// Emoji of the day type, with its name when there is room.
class _TypeIcon extends StatelessWidget {
  const new({required this.type, required this.showName});

  final DiaryDayType type;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final emoji = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(diaryDayTypeEmoji(type), style: textTheme.headlineMedium),
    );
    if (!showName) {
      return Semantics(
        label: diaryDayTypeLabel(type, l10n),
        excludeSemantics: true,
        child: Center(child: emoji),
      );
    }
    return Row(
      spacing: AppSpacing.sm,
      children: [
        emoji,
        Expanded(
          child: Text(
            diaryDayTypeLabel(type, l10n),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              fontFamily: AppFonts.geist,
              fontWeight: FontWeight.w600,
              color: FoodLabelColors.of(context).ink,
            ),
          ),
        ),
      ],
    );
  }
}

/// A training or pause button; pressed, it is filled.
class _TypeButton extends StatelessWidget {
  const new({required this.type, required this.selected, required this.onTap});

  final DiaryDayType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: diaryDayTypeLabel(type, l10n),
      onTap: onTap,
      excludeSemantics: true,
      child: AppInkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: selected ? colors.ink : colors.paper,
            shape: const StadiumBorder(),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
            child: Center(
              child: Icon(
                diaryBudgetDayTypeIcon(type),
                size: AppDashboard.dayTypeIcon,
                color: selected ? colors.tile : colors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The current day type as one round button; a tap switches training.
class _CurrentTypeButton extends StatelessWidget {
  const new({required this.type, required this.onTap});

  final DiaryDayType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final pressed = type != DiaryDayType.normal;

    return Semantics(
      button: true,
      selected: type == DiaryDayType.training,
      label: l10n.diaryDayTypeTileSemantics(diaryDayTypeLabel(type, l10n)),
      onTap: onTap,
      excludeSemantics: true,
      child: AppInkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: pressed ? colors.ink : colors.paper,
            shape: const CircleBorder(),
          ),
          child: Center(
            child: Icon(
              diaryBudgetDayTypeIcon(type),
              size: AppDashboard.dayTypeIcon,
              color: pressed ? colors.tile : colors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
