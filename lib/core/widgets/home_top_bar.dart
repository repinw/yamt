import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/home_top_bar_actions.dart';

const _regularHomeTopBarHeight = 76.0;
const _compactHomeTopBarHeight = 88.0;
const double _homeTopBarTextVerticalPadding = AppSpacing.xxl;

/// Top app bar used by the home shell pages.
class HomeTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// The home top bar.
  const new({
    required this.title,
    required this.actions,
    super.key,
    this.compact = false,
    this.preferredHeight,
    this.titleColor,
  });

  /// The title.
  final String title;

  /// The actions.
  final List<Widget> actions;

  /// Whether to use compact spacing for tight layouts.
  final bool compact;

  /// Optional precomputed preferred height for context-dependent layouts.
  final double? preferredHeight;

  /// The title color.
  final Color? titleColor;

  /// Computes a preferred height that accounts for accessibility text scaling.
  static double preferredHeightFor(
    BuildContext context, {
    required bool compact,
  }) {
    final titleStyle = _titleStyle(context, compact: compact);
    final painter = TextPainter(
      text: TextSpan(text: 'Ag', style: titleStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final baseHeight = compact
        ? _compactHomeTopBarHeight
        : _regularHomeTopBarHeight;
    final contentHeight = painter.height + _homeTopBarTextVerticalPadding;
    return baseHeight < contentHeight ? contentHeight : baseHeight;
  }

  @override
  Size get preferredSize => Size.fromHeight(
    preferredHeight ??
        (compact ? _compactHomeTopBarHeight : _regularHomeTopBarHeight),
  );
  @override
  Widget build(BuildContext context) {
    final resolvedHeight =
        preferredHeight ?? preferredHeightFor(context, compact: compact);
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: resolvedHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.lg : AppSpacing.xl,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _titleStyle(
                    context,
                    compact: compact,
                    color: titleColor,
                  ),
                ),
              ),
              if (actions.isNotEmpty)
                SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
              HomeTopBarActions(actions: actions),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle? _titleStyle(
  BuildContext context, {
  required bool compact,
  Color? color,
}) =>
    (compact
            ? Theme.of(context).textTheme.titleLarge
            : Theme.of(context).textTheme.headlineSmall)
        ?.copyWith(
          color: color ?? Theme.of(context).colorScheme.onSurface,
          fontSize: compact
              ? AppFontSizes.homeTabTitleCompact
              : AppFontSizes.homeTabTitle,
          fontWeight: FontWeight.w800,
        );
