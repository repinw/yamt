import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Text labels used by [showWeightEntryDialog].
@immutable
class WeightEntryDialogLabels {
  /// Creates weight entry dialog labels.
  const WeightEntryDialogLabels({
    required this.title,
    required this.fieldLabel,
    required this.emptyErrorText,
    required this.invalidErrorText,
    required this.clearActionLabel,
    required this.cancelActionLabel,
    required this.saveActionLabel,
  });

  /// Dialog title.
  final String title;

  /// Weight input label.
  final String fieldLabel;

  /// Error shown when the input is empty.
  final String emptyErrorText;

  /// Error shown when the input is invalid.
  final String invalidErrorText;

  /// Clear action label.
  final String clearActionLabel;

  /// Cancel action label.
  final String cancelActionLabel;

  /// Save action label.
  final String saveActionLabel;
}

/// Optional widget keys used by [showWeightEntryDialog].
@immutable
class WeightEntryDialogKeys {
  /// Creates weight entry dialog keys.
  const WeightEntryDialogKeys({
    this.fieldKey,
    this.clearButtonKey,
    this.saveButtonKey,
  });

  /// Key for the text field.
  final Key? fieldKey;

  /// Key for the clear button.
  final Key? clearButtonKey;

  /// Key for the save button.
  final Key? saveButtonKey;
}

/// Action selected in a weight entry dialog.
enum WeightEntryDialogAction {
  /// Save the entered weight.
  save,

  /// Clear the existing weight.
  clear,
}

/// Result returned by [showWeightEntryDialog].
@immutable
class WeightEntryDialogResult {
  const WeightEntryDialogResult._({
    required this.action,
    this.weightKg,
  });

  /// Creates a clear result.
  const WeightEntryDialogResult.clear()
    : this._(action: WeightEntryDialogAction.clear);

  /// Creates a save result.
  const WeightEntryDialogResult.save(double weightKg)
    : this._(action: WeightEntryDialogAction.save, weightKg: weightKg);

  /// Selected action.
  final WeightEntryDialogAction action;

  /// Entered weight for save actions.
  final double? weightKg;
}

/// Shows a reusable weight entry dialog.
Future<WeightEntryDialogResult?> showWeightEntryDialog({
  required BuildContext context,
  required WeightEntryDialogLabels labels,
  required double? initialWeightKg,
  required bool showClearAction,
  WeightEntryDialogKeys keys = const WeightEntryDialogKeys(),
}) {
  return showDialog<WeightEntryDialogResult>(
    context: context,
    builder: (context) {
      return _WeightEntryDialogContent(
        labels: labels,
        keys: keys,
        initialWeightKg: initialWeightKg,
        showClearAction: showClearAction,
      );
    },
  );
}

class _WeightEntryDialogContent extends StatefulWidget {
  const _WeightEntryDialogContent({
    required this.labels,
    required this.keys,
    required this.initialWeightKg,
    required this.showClearAction,
  });

  final WeightEntryDialogLabels labels;
  final WeightEntryDialogKeys keys;
  final double? initialWeightKg;
  final bool showClearAction;

  @override
  State<_WeightEntryDialogContent> createState() =>
      _WeightEntryDialogContentState();
}

class _WeightEntryDialogContentState extends State<_WeightEntryDialogContent> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialWeightKg?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    return AlertDialog(
      scrollable: true,
      title: Text(labels.title),
      content: TextField(
        key: widget.keys.fieldKey,
        controller: _controller,
        keyboardType: _weightKeyboardType,
        textInputAction: TextInputAction.done,
        autocorrect: false,
        enableSuggestions: false,
        onSubmitted: (_) => _save(),
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        decoration: InputDecoration(
          labelText: labels.fieldLabel,
          errorText: _errorText,
        ),
      ),
      actions: <Widget>[
        if (widget.showClearAction)
          TextButton(
            key: widget.keys.clearButtonKey,
            onPressed: () => Navigator.of(
              context,
            ).pop(const WeightEntryDialogResult.clear()),
            child: Text(labels.clearActionLabel),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(labels.cancelActionLabel),
        ),
        FilledButton(
          key: widget.keys.saveButtonKey,
          onPressed: _save,
          child: Text(labels.saveActionLabel),
        ),
      ],
    );
  }

  void _save() {
    final labels = widget.labels;
    final rawWeight = _controller.text.trim().replaceAll(',', '.');
    if (rawWeight.isEmpty) {
      setState(() {
        _errorText = labels.emptyErrorText;
      });
      return;
    }

    final parsedWeight = double.tryParse(rawWeight);
    if (parsedWeight == null || parsedWeight <= 0) {
      setState(() {
        _errorText = labels.invalidErrorText;
      });
      return;
    }

    Navigator.of(
      context,
    ).pop(WeightEntryDialogResult.save(parsedWeight));
  }
}

TextInputType get _weightKeyboardType {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return TextInputType.text;
  }
  return const TextInputType.numberWithOptions(decimal: true);
}
