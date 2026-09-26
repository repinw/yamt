import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/domain/diary_meal_entry_group.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_combined_food_row.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_meal_entry_tile.dart';

/// One row per food. A merged group expands on tap to its single entries,
/// and a combined entry to its foods; a single entry opens directly.
class DiaryMealEntryGroupTile extends StatefulWidget {
  /// Creates the group row.
  const new({required this.group, required this.onTapEntry, super.key});

  /// Entries of one food.
  final DiaryMealEntryGroup group;

  /// Called when a single entry is tapped.
  final ValueChanged<DiaryMealEntry> onTapEntry;

  @override
  State<DiaryMealEntryGroupTile> createState() =>
      _DiaryMealEntryGroupTileState();
}

class _DiaryMealEntryGroupTileState extends State<DiaryMealEntryGroupTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final combinedFoods = group.isMerged
        ? null
        : group.entries.single.combinedFoods;
    if (!group.isMerged && combinedFoods == null) {
      final entry = group.entries.single;
      return DiaryMealEntryTile(
        entry: entry,
        onTap: () => widget.onTapEntry(entry),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiaryMealEntryTile(
          entry: group.combined,
          count: combinedFoods?.length ?? group.entries.length,
          expanded: _expanded,
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        AnimatedSize(
          duration: AppDurations.compactMetricExpansion,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xxxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (combinedFoods != null)
                        for (final (index, food) in combinedFoods.indexed)
                          DiaryCombinedFoodRow(
                            key: ValueKey<int>(index),
                            food: food,
                            onTap: () =>
                                widget.onTapEntry(group.entries.single),
                          )
                      else
                        for (final entry in group.entries)
                          DiaryMealEntryTile(
                            key: ValueKey<String>(entry.id),
                            entry: entry,
                            onTap: () => widget.onTapEntry(entry),
                          ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
