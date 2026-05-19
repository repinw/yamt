import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';

const _compactHomeChromeTextScaleThreshold = 1.15;
const _bottomNavLabelMinItemWidth = 64.0;
const _regularHomeTopBarHeight = 76.0;
const _compactHomeTopBarHeight = 88.0;
const _regularHomeTopBarWithSubtitleHeight = 86.0;
const _compactHomeTopBarWithSubtitleHeight = 96.0;
const _bottomNavTopIndicatorWidth = 20.0;
const _shellChromeMotionDuration = Duration(milliseconds: 220);
const double _homeTopBarTextVerticalPadding = AppSpacing.xxl;

double _effectiveTextScale(
  BuildContext context, {
  double referenceFontSize = 14,
}) {
  return MediaQuery.textScalerOf(
        context,
      ).scale(referenceFontSize) /
      referenceFontSize;
}

double _preferredHomeTopBarBaseHeight({
  required bool compact,
  required bool hasSubtitle,
}) {
  if (hasSubtitle) {
    return compact
        ? _compactHomeTopBarWithSubtitleHeight
        : _regularHomeTopBarWithSubtitleHeight;
  }

  return compact ? _compactHomeTopBarHeight : _regularHomeTopBarHeight;
}

TextStyle? _homeTopBarTitleStyle(
  BuildContext context, {
  required bool compact,
  required bool hasSubtitle,
  Color? color,
}) {
  final textTheme = Theme.of(context).textTheme;
  return (compact ? textTheme.titleLarge : textTheme.headlineSmall)?.copyWith(
    color: color ?? Theme.of(context).colorScheme.onSurface,
    fontSize: compact
        ? AppFontSizes.homeTabTitleCompact
        : AppFontSizes.homeTabTitle,
    fontWeight: FontWeight.w800,
    height: hasSubtitle ? 1 : null,
  );
}

TextStyle? _homeTopBarSubtitleStyle(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  return Theme.of(context).textTheme.labelLarge?.copyWith(
    color: colors.onSurfaceVariant,
    fontSize: AppFontSizes.homeTabSubtitle,
    fontWeight: FontWeight.w700,
  );
}

double _scaledTextLineHeight(BuildContext context, TextStyle? style) {
  final painter = TextPainter(
    text: TextSpan(text: 'Ag', style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  return painter.height;
}

/// Whether shared home chrome should switch to its compact layout.
bool shouldUseCompactHomeChrome(BuildContext context) {
  return isCompactViewport(context) ||
      _effectiveTextScale(context) > _compactHomeChromeTextScaleThreshold;
}

bool _shouldShowBottomNavLabels(
  List<HomeNavEntry> entries, {
  required double maxWidth,
  required double navHorizontalPadding,
}) {
  if (entries.isEmpty) {
    return false;
  }

  final availablePerItem =
      (maxWidth - (navHorizontalPadding * 2)) / entries.length;
  return availablePerItem >= _bottomNavLabelMinItemWidth;
}

double _clampChromeVisibility(double visibility) {
  return visibility.clamp(0.0, 1.0);
}

/// Tabs shown in the shared home shell.
enum HomeTabType {
  /// Inventory.
  inventory,

  /// Diary.
  diary,

  /// Cookbook.
  cookbook,

  /// Statistics.
  statistics,

  /// Settings.
  settings,
}

/// Floating sliver that hosts the shared home top chrome.
class HomeShellTopSliverChrome extends StatelessWidget {
  /// The shell top chrome sliver.
  const HomeShellTopSliverChrome({
    required this.child,
    super.key,
  });

  /// The visible app bar.
  final PreferredSizeWidget child;

  @override
  Widget build(BuildContext context) {
    final statusBarInset = MediaQuery.paddingOf(context).top;
    final toolbarHeight = child.preferredSize.height;

    return SliverPersistentHeader(
      floating: true,
      delegate: _HomeShellTopChromeDelegate(
        child: child,
        statusBarInset: statusBarInset,
        toolbarHeight: toolbarHeight,
      ),
    );
  }
}

class _HomeShellTopChromeDelegate extends SliverPersistentHeaderDelegate {
  const _HomeShellTopChromeDelegate({
    required this.child,
    required this.statusBarInset,
    required this.toolbarHeight,
  });

  final PreferredSizeWidget child;
  final double statusBarInset;
  final double toolbarHeight;

  @override
  double get minExtent => 0;

  @override
  double get maxExtent => statusBarInset + toolbarHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    if (maxExtent <= 0) {
      return const SizedBox.shrink();
    }

    final visibility = _clampChromeVisibility(
      (maxExtent - shrinkOffset) / maxExtent,
    );

    if (visibility <= 0) {
      return const SizedBox.shrink();
    }

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: maxExtent,
        maxHeight: maxExtent,
        // Keep the surface painted behind the system status bar.
        child: Transform.translate(
          offset: Offset(0, -toolbarHeight * (1 - visibility)),
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeShellTopChromeDelegate oldDelegate) {
    return child != oldDelegate.child ||
        statusBarInset != oldDelegate.statusBarInset ||
        toolbarHeight != oldDelegate.toolbarHeight;
  }
}

/// Top app bar used by the home shell pages.
class HomeTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// The home top bar.
  const HomeTopBar({
    required this.title,
    required this.actions,
    super.key,
    this.compact = false,
    this.middle,
    this.preferredHeight,
    this.titleColor,
    this.titleIcon,
    this.subtitle,
  });

  /// The title.
  final String title;

  /// The actions.
  final List<Widget> actions;

  /// Whether to use compact spacing for tight layouts.
  final bool compact;

  /// Optional widget shown between title and actions.
  final Widget? middle;

  /// Optional precomputed preferred height for context-dependent layouts.
  final double? preferredHeight;

  /// The title color.
  final Color? titleColor;

  /// The title icon.
  final IconData? titleIcon;

  /// Optional subtitle shown below the title.
  final String? subtitle;

  /// Computes a preferred height that accounts for accessibility text scaling.
  static double preferredHeightFor(
    BuildContext context, {
    required bool compact,
    required bool hasSubtitle,
  }) {
    final baseHeight = _preferredHomeTopBarBaseHeight(
      compact: compact,
      hasSubtitle: hasSubtitle,
    );
    final titleHeight = _scaledTextLineHeight(
      context,
      _homeTopBarTitleStyle(
        context,
        compact: compact,
        hasSubtitle: hasSubtitle,
      ),
    );
    final subtitleHeight = hasSubtitle
        ? _scaledTextLineHeight(context, _homeTopBarSubtitleStyle(context))
        : 0.0;
    final contentHeight =
        titleHeight +
        subtitleHeight +
        (hasSubtitle ? AppSpacing.xxs : 0.0) +
        _homeTopBarTextVerticalPadding;

    return baseHeight < contentHeight ? contentHeight : baseHeight;
  }

  @override
  Size get preferredSize {
    return Size.fromHeight(
      preferredHeight ??
          _preferredHomeTopBarBaseHeight(
            compact: compact,
            hasSubtitle: subtitle != null,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final resolvedHeight =
        preferredHeight ??
        preferredHeightFor(
          context,
          compact: compact,
          hasSubtitle: subtitle != null,
        );
    final titleStyle = _homeTopBarTitleStyle(
      context,
      compact: compact,
      hasSubtitle: subtitle != null,
      color: titleColor,
    );
    final subtitleStyle = _homeTopBarSubtitleStyle(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppEditorialSurfaces.appBackground(colors),
      ),
      child: SafeArea(
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
                  child: Row(
                    children: [
                      if (titleIcon != null) ...[
                        Icon(
                          titleIcon,
                          color: titleColor ?? colors.primary,
                          size: compact ? 20 : 22,
                        ),
                        SizedBox(
                          width: compact ? AppSpacing.xs : AppSpacing.sm,
                        ),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle,
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: subtitleStyle,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (middle != null) ...[
                  SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
                  middle!,
                ],
                if (actions.isNotEmpty)
                  SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
                _HomeTopBarActions(actions: actions),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTopBarActions extends StatelessWidget {
  const _HomeTopBarActions({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: AppEditorialSurfaces.section(colors),
          disabledBackgroundColor: AppEditorialSurfaces.section(
            colors,
          ).withValues(alpha: 0.6),
          disabledForegroundColor: colors.onSurfaceVariant.withValues(
            alpha: 0.48,
          ),
          fixedSize: const Size.square(AppSizes.homeTopBarIconButton),
          foregroundColor: colors.onSurfaceVariant,
          minimumSize: const Size.square(AppSizes.homeTopBarIconButton),
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < actions.length; index += 1) ...[
            if (index > 0) const SizedBox(width: AppSpacing.xs),
            actions[index],
          ],
        ],
      ),
    );
  }
}

/// Data needed to render one item in the home bottom navigation.
class HomeNavItem {
  /// The home nav item.
  const HomeNavItem({required this.icon, required this.label});

  /// The icon.
  final IconData icon;

  /// The label.
  final String label;
}

/// UI state and action for a single home navigation entry.
class HomeNavEntry {
  /// The home nav entry.
  const HomeNavEntry({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.showTopIndicator = false,
  });

  /// The item.
  final HomeNavItem item;

  /// Whether selected.
  final bool isSelected;

  /// Whether to show a small top indicator above this entry.
  final bool showTopIndicator;

  /// The on tap.
  final VoidCallback onTap;
}

/// Collapses and fades the shared home bottom chrome.
class HomeShellBottomChrome extends StatelessWidget {
  /// The shell bottom chrome transition.
  const HomeShellBottomChrome({
    required this.child,
    required this.visibility,
    super.key,
  });

  /// The visible bottom chrome.
  final Widget child;

  /// How much chrome is visible, from 0 to 1.
  final double visibility;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _clampChromeVisibility(visibility)),
      duration: _shellChromeMotionDuration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, effectiveVisibility, chromeChild) {
        return IgnorePointer(
          ignoring: effectiveVisibility < 0.05,
          child: Opacity(
            opacity: effectiveVisibility,
            child: Transform.translate(
              offset: Offset(
                0,
                AppSizes.homeShellBottomBarClearance *
                    (1 - effectiveVisibility),
              ),
              child: chromeChild,
            ),
          ),
        );
      },
    );
  }
}

/// Moves the home floating action button with the shared bottom chrome.
class HomeShellFloatingActionButtonChrome extends StatelessWidget {
  /// The shell floating action button transition.
  const HomeShellFloatingActionButtonChrome({
    required this.child,
    required this.visibility,
    super.key,
  });

  /// The visible floating action button.
  final Widget child;

  /// How much bottom chrome is visible, from 0 to 1.
  final double visibility;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _clampChromeVisibility(visibility)),
      duration: _shellChromeMotionDuration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, effectiveVisibility, fabChild) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: AppSizes.homeShellBottomBarClearance * effectiveVisibility,
          ),
          child: fabChild,
        );
      },
    );
  }
}

/// Bottom navigation bar used by the home shell pages.
class HomeBottomNavBar extends StatelessWidget {
  /// The home bottom nav bar.
  const HomeBottomNavBar({required this.entries, super.key});

  /// The entries.
  final List<HomeNavEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compactChrome = shouldUseCompactHomeChrome(context);
    final radius = BorderRadius.circular(AppEditorial.cardRadius);
    final horizontalInset = compactChrome ? AppSpacing.xxs : AppSpacing.xs;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalInset,
          0,
          horizontalInset,
          AppSpacing.xl,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              AppEditorialSurfaces.ambientBoxShadow(
                colors,
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppEditorialSurfaces.section(colors),
                borderRadius: radius,
                border: Border.all(
                  color: AppEditorialSurfaces.solidCardBorder(colors),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final navHorizontalPadding = compactChrome
                      ? AppSpacing.xs
                      : AppSpacing.xs;
                  final showLabels = _shouldShowBottomNavLabels(
                    entries,
                    maxWidth: constraints.maxWidth,
                    navHorizontalPadding: navHorizontalPadding,
                  );

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      navHorizontalPadding,
                      compactChrome ? AppSpacing.xs : AppSpacing.sm,
                      navHorizontalPadding,
                      compactChrome ? AppSpacing.sm : AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        for (final entry in entries)
                          Expanded(
                            child: _HomeBottomNavItemButton(
                              item: entry.item,
                              isSelected: entry.isSelected,
                              showTopIndicator: entry.showTopIndicator,
                              onTap: entry.onTap,
                              showLabel: showLabels,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeBottomNavItemButton extends StatelessWidget {
  const _HomeBottomNavItemButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.showLabel,
    required this.showTopIndicator,
  });

  final HomeNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showLabel;
  final bool showTopIndicator;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foregroundColor = isSelected
        ? colors.primary
        : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: AppInkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          padding: EdgeInsets.symmetric(
            horizontal: showLabel ? AppSpacing.xs : AppSpacing.xxs,
            vertical: showLabel ? AppSpacing.sm : AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: showTopIndicator ? _bottomNavTopIndicatorWidth : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: showTopIndicator ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              SizedBox(height: showTopIndicator ? AppSpacing.xs : 0),
              Icon(
                item.icon,
                color: foregroundColor,
                size: showLabel ? 22 : 24,
              ),
              if (showLabel) ...[
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foregroundColor,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
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
