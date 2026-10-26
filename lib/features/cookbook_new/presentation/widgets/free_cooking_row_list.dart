import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_row.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_transcript.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_row_tile.dart';

/// The ingredient rows, newest last, plus the row that speech recognition is
/// still writing. A swipe removes a row, a tap opens "Zeile füllen".
class FreeCookingRowList extends StatefulWidget {
  /// Creates the list of [rows] with the unfinished [pendingText].
  const new({
    required this.rows,
    required this.pendingText,
    required this.onRemove,
    this.onPick,
    super.key,
  });

  /// Key of the row at [index].
  static ValueKey<String> rowKey(int index) =>
      ValueKey<String>('free-cooking-row-$index');

  /// Key of the spoken row at [index] that is not final yet.
  static ValueKey<String> pendingRowKey(int index) =>
      ValueKey<String>('free-cooking-pending-row-$index');

  /// The ingredient rows.
  final List<FreeCookingRow> rows;

  /// What speech recognition heard so far, or `null`.
  final String? pendingText;

  /// Removes the row at an index.
  final ValueChanged<int> onRemove;

  /// Opens "Zeile füllen" for the row at an index, or `null` while the
  /// rows cannot change.
  final ValueChanged<int>? onPick;

  @override
  State<FreeCookingRowList> createState() => _FreeCookingRowListState();
}

class _FreeCookingRowListState extends State<FreeCookingRowList> {
  final _controller = ScrollController();

  @override
  void didUpdateWidget(FreeCookingRowList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // New rows and the row being spoken appear at the end; keep them in view.
    if (widget.rows.length > oldWidget.rows.length ||
        widget.pendingText != oldWidget.pendingText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpTo(_controller.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final rows = widget.rows;
    // What is being spoken shows as the rows it will give.
    final pending = switch (widget.pendingText) {
      final text? => previewFreeCookingRows(text),
      null => const <String>[],
    };
    final onPick = widget.onPick;
    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      itemCount: rows.length + pending.length,
      itemBuilder: (context, index) {
        if (index >= rows.length) {
          return Opacity(
            opacity: AppGraphit.pendingRowOpacity,
            child: FreeCookingRowTile(
              key: FreeCookingRowList.pendingRowKey(index - rows.length),
              row: FreeCookingRow(text: pending[index - rows.length]),
              isPending: true,
            ),
          );
        }
        final row = rows[index];
        return Dismissible(
          key: ValueKey<String>('${rows.length}-$index-${row.text}'),
          onDismissed: (_) => widget.onRemove(index),
          background: ColoredBox(color: colors.low),
          child: FreeCookingRowTile(
            key: FreeCookingRowList.rowKey(index),
            row: row,
            onTap: onPick == null || row.candidates.isEmpty
                ? null
                : () => onPick(index),
          ),
        );
      },
    );
  }
}
