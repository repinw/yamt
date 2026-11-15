import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// A labeled row of removable pills with an add chip that turns into an
/// inline input. Used for the wishes and the stored "Bloß nicht" list.
class AiChefPillRow extends StatefulWidget {
  /// Creates the row.
  const new({
    required this.keyPrefix,
    required this.label,
    required this.addLabel,
    required this.hint,
    required this.entries,
    required this.onAdd,
    required this.onRemove,
    this.errorText,
    this.onRetry,
    super.key,
  });

  /// Key of the chip that opens the input.
  static ValueKey<String> addKey(String prefix) =>
      ValueKey<String>('$prefix-add');

  /// Key of the action that loads the entries again.
  static ValueKey<String> retryKey(String prefix) =>
      ValueKey<String>('$prefix-retry');

  /// Key of the input for a new entry.
  static ValueKey<String> inputKey(String prefix) =>
      ValueKey<String>('$prefix-input');

  /// Key of the pill for [entry].
  static ValueKey<String> chipKey(String prefix, String entry) =>
      ValueKey<String>('$prefix-chip-$entry');

  /// Prefix of the keys of this row.
  final String keyPrefix;

  /// Text above the pills.
  final String label;

  /// Text of the add chip.
  final String addLabel;

  /// Hint in the input.
  final String hint;

  /// The entries, or null while they load.
  final List<String>? entries;

  /// Says that loading or saving the entries failed.
  final String? errorText;

  /// Called to load the entries again; without it the error shows no
  /// retry.
  final VoidCallback? onRetry;

  /// Called with a new entry.
  final ValueChanged<String> onAdd;

  /// Called with the entry to remove.
  final ValueChanged<String> onRemove;

  @override
  State<AiChefPillRow> createState() => _AiChefPillRowState();
}

class _AiChefPillRowState extends State<AiChefPillRow> {
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  var _isAdding = false;

  @override
  void initState() {
    super.initState();
    _inputFocus.addListener(_submitOnFocusLoss);
  }

  @override
  void dispose() {
    _inputFocus.removeListener(_submitOnFocusLoss);
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // Leaving the field keeps what was typed, also when the user taps
  // "Rezept vorschlagen" right away.
  void _submitOnFocusLoss() {
    if (!_inputFocus.hasFocus && _isAdding) {
      _submit(_inputController.text);
    }
  }

  void _startAdding() {
    setState(() {
      _isAdding = true;
    });
    _inputFocus.requestFocus();
  }

  void _submit(String value) {
    if (!_isAdding) {
      return;
    }
    if (value.trim().isNotEmpty) {
      widget.onAdd(value);
    }
    _inputController.clear();
    setState(() {
      _isAdding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final prefix = widget.keyPrefix;
    final entries = widget.entries;
    final errorText = widget.errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.sm),
        if (errorText != null)
          Row(
            children: [
              Expanded(
                child: Text(
                  errorText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              if (widget.onRetry case final onRetry?)
                TextButton(
                  key: AiChefPillRow.retryKey(prefix),
                  onPressed: onRetry,
                  child: Text(l10n.productSearchHubSearchRetryAction),
                ),
            ],
          ),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final entry in entries ?? const <String>[])
              InputChip(
                key: AiChefPillRow.chipKey(prefix, entry),
                label: Text(entry),
                onDeleted: () => widget.onRemove(entry),
                deleteButtonTooltipMessage: l10n.aiChefExclusionsRemoveTooltip(
                  entry,
                ),
              ),
            if (_isAdding)
              SizedBox(
                width: AppSizes.inlineChipInputWidth,
                child: TextField(
                  key: AiChefPillRow.inputKey(prefix),
                  controller: _inputController,
                  focusNode: _inputFocus,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.hint,
                  ),
                  onSubmitted: _submit,
                  onTapUpOutside: (_) => _inputFocus.unfocus(),
                ),
              )
            else
              ActionChip(
                key: AiChefPillRow.addKey(prefix),
                avatar: const Icon(Icons.add_rounded),
                label: Text(widget.addLabel),
                onPressed: entries == null ? null : _startAdding,
              ),
          ],
        ),
      ],
    );
  }
}
