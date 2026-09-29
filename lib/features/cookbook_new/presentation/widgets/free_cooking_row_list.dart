import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_row.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_row_tile.dart';

/// The ingredient rows, newest last, plus the row that speech recognition is
/// still writing. A swipe removes a row.
class FreeCookingRowList extends StatefulWidget {
  /// Creates the list of [rows] with the unfinished [pendingText].
  const new({
    required this.rows,
    required this.pendingText,
    required this.onRemove,
    super.key,
  });

  /// Key of the row at [index].
  static ValueKey<String> rowKey(int index) =>
      ValueKey<String>('free-cooking-row-$index');

  /// The ingredient rows.
  final List<FreeCookingRow> rows;

  /// What speech recognition heard so far, or `null`.
  final String? pendingText;

  /// Removes the row at an index.
  final ValueChanged<int> onRemove;

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
    final pending = widget.pendingText;
    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      itemCount: rows.length + (pending == null ? 0 : 1),
      itemBuilder: (context, index) {
        if (index == rows.length) {
          return Opacity(
            opacity: AppGraphit.pendingRowOpacity,
            child: FreeCookingRowTile(
              row: FreeCookingRow(text: pending!),
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
          ),
        );
      },
    );
  }
}
