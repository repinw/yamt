import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

const _regularHomeTopBarHeight = 76.0;
const _compactHomeTopBarHeight = 88.0;
const double _homeTopBarTextVerticalPadding = AppSpacing.xxl;

/// Largest share of the screen width that the tools may take.
const _toolsMaxWidthShare = 0.75;

/// Top app bar used by the home shell pages: the tab title in ink and the
/// tab's labeled tools.
class HomeTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// The home top bar.
  const new({
    required this.title,
    required this.tools,
    super.key,
    this.compact = false,
    this.preferredHeight,
    this.kicker,
  });

  /// The title.
  final String title;

  /// Small uppercase caption above the title, such as "23 Lebensmittel".
  final String? kicker;

  /// Labeled tools at the end of the bar, usually `HomeHeaderTool`s.
  final List<Widget> tools;

  /// Whether to use compact spacing for tight layouts.
  final bool compact;

  /// Optional precomputed preferred height for context-dependent layouts.
  final double? preferredHeight;

  /// Computes a preferred height that accounts for accessibility text scaling.
  static double preferredHeightFor(
    BuildContext context, {
    required bool compact,
    bool hasKicker = false,
  }) {
    double lineHeight(TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(text: 'Ag', style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      return painter.height;
    }

    final baseHeight = compact
        ? _compactHomeTopBarHeight
        : _regularHomeTopBarHeight;
    final kickerHeight = hasKicker
        ? lineHeight(_kickerStyle(context)) + AppSpacing.xxs
        : 0.0;
    final contentHeight =
        lineHeight(_titleStyle(context, compact: compact)) +
        kickerHeight +
        _homeTopBarTextVerticalPadding;
    return baseHeight < contentHeight ? contentHeight : baseHeight;
  }

  @override
  Size get preferredSize => Size.fromHeight(
    preferredHeight ??
        (compact ? _compactHomeTopBarHeight : _regularHomeTopBarHeight),
  );
  @override
  Widget build(BuildContext context) {
    final kicker = this.kicker;
    final resolvedHeight =
        preferredHeight ??
        preferredHeightFor(
          context,
          compact: compact,
          hasKicker: kicker != null,
        );
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.xxs,
                  children: [
                    if (kicker != null)
                      Text(
                        kicker.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _kickerStyle(context),
                      ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _titleStyle(context, compact: compact),
                    ),
                  ],
                ),
              ),
              if (tools.isNotEmpty) ...[
                SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
                // Large text scales the tools down instead of pushing the
                // bar wider than the screen.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.sizeOf(context).width * _toolsMaxWidthShare,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(mainAxisSize: MainAxisSize.min, children: tools),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle? _titleStyle(BuildContext context, {required bool compact}) =>
    (compact
            ? Theme.of(context).textTheme.titleLarge
            : Theme.of(context).textTheme.headlineSmall)
        ?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: compact
              ? AppFontSizes.homeTabTitleCompact
              : AppFontSizes.homeTabTitle,
          fontWeight: FontWeight.w800,
        );

TextStyle? _kickerStyle(BuildContext context) =>
    Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: AppGraphit.kickerTracking,
    );
