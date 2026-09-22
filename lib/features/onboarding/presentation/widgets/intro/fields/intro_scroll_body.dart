import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';

/// Scrollable page body that keeps its content vertically centred.
///
/// The content grows downwards once it is taller than the viewport, so short
/// pages sit in the middle and long pages still scroll.
class IntroScrollBody extends StatelessWidget {
  /// Creates a centred scroll body.
  const new({
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    super.key,
  });

  /// Content of the page.
  final List<Widget> children;

  /// Horizontal alignment of the content.
  final CrossAxisAlignment crossAxisAlignment;

  static const _padding = EdgeInsets.only(
    top: AppIntroLayout.chromeClearance,
    bottom: AppIntroLayout.controlsClearance,
    left: AppSpacing.lg,
    right: AppSpacing.lg,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.maxHeight - _padding.vertical;

        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: _padding,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minHeight > 0 ? minHeight : 0,
                maxWidth: AppSizes.narrowContentMaxWidth,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: crossAxisAlignment,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}
