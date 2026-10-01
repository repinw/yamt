import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows a "Done" bar above the keyboard while an iOS number field has focus.
///
/// The iOS number and phone keyboards have no return key, so without this bar
/// the user cannot close them.
class KeyboardDoneBar extends StatefulWidget {
  /// Creates a keyboard done bar around [child].
  const new({required this.child, super.key});

  /// App content below the bar.
  final Widget child;

  @override
  State<KeyboardDoneBar> createState() => _KeyboardDoneBarState();
}

class _KeyboardDoneBarState extends State<KeyboardDoneBar> {
  bool _numberFieldFocused = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _handleFocusChanged() {
    final focused = _isNumberFieldFocused();
    if (focused == _numberFieldFocused) return;
    setState(() => _numberFieldFocused = focused);
  }

  bool _isNumberFieldFocused() {
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    final editable = FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<EditableText>();
    final keyboardType = editable?.keyboardType;
    return keyboardType?.index == TextInputType.number.index ||
        keyboardType?.index == TextInputType.phone.index;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final showBar = _numberFieldFocused && keyboardHeight > 0;
    // The bar grows with the text size; its label always fits this height.
    final barHeight = mediaQuery.textScaler.scale(AppSizes.minTapTarget);

    // While the bar shows, the app sees a keyboard that is taller by the
    // bar, so pages and sheets keep their content above the bar.
    return Stack(
      children: [
        MediaQuery(
          data: showBar
              ? mediaQuery.copyWith(
                  viewInsets: mediaQuery.viewInsets.copyWith(
                    bottom: keyboardHeight + barHeight,
                  ),
                )
              : mediaQuery,
          child: widget.child,
        ),
        if (showBar)
          Positioned(
            left: 0,
            right: 0,
            bottom: keyboardHeight,
            child: _KeyboardDoneBarContent(height: barHeight),
          ),
      ],
    );
  }
}

class _KeyboardDoneBarContent extends StatelessWidget {
  const new({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: TextButton(
            key: const Key('keyboard_done_bar_button'),
            onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Text(AppLocalizations.of(context)!.keyboardDoneAction),
          ),
        ),
      ),
    );
  }
}
