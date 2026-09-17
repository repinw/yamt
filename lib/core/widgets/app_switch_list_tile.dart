// Mirrors Flutter's switch tile APIs; delegated property docs stay in SDK.
// ignore_for_file: deprecated_member_use, public_member_api_docs

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_haptic_feedback.dart';

/// App-standard [SwitchListTile] with Material feedback disabled centrally.
class AppSwitchListTile extends StatelessWidget {
  /// Creates an app switch list tile.
  const new({
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.activeThumbColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.activeThumbImage,
    this.onActiveThumbImageError,
    this.inactiveThumbImage,
    this.onInactiveThumbImageError,
    this.thumbColor,
    this.trackColor,
    this.trackOutlineColor,
    this.thumbIcon,
    this.materialTapTargetSize,
    this.dragStartBehavior = DragStartBehavior.start,
    this.mouseCursor,
    this.overlayColor,
    this.splashRadius,
    this.focusNode,
    this.onFocusChange,
    this.autofocus = false,
    this.tileColor,
    this.title,
    this.subtitle,
    this.isThreeLine,
    this.dense,
    this.contentPadding,
    this.secondary,
    this.selected = false,
    this.controlAffinity,
    this.shape,
    this.selectedTileColor,
    this.visualDensity,
    this.horizontalTitleGap,
    this.minVerticalPadding,
    this.minLeadingWidth,
    this.minTileHeight,
    this.hoverColor,
    this.internalAddSemanticForOnTap = false,
    super.key,
  }) : _adaptive = false,
       applyCupertinoTheme = null;

  /// Creates an adaptive app switch list tile.
  const new adaptive({
    required this.value,
    required this.onChanged,
    this.applyCupertinoTheme,
    this.internalAddSemanticForOnTap = false,
    this.hoverColor,
    this.minTileHeight,
    this.minLeadingWidth,
    this.minVerticalPadding,
    this.horizontalTitleGap,
    this.visualDensity,
    this.selectedTileColor,
    this.shape,
    this.controlAffinity,
    this.selected = false,
    this.secondary,
    this.contentPadding,
    this.dense,
    this.isThreeLine,
    this.subtitle,
    this.title,
    this.tileColor,
    this.autofocus = false,
    this.onFocusChange,
    this.focusNode,
    this.splashRadius,
    this.overlayColor,
    this.mouseCursor,
    this.dragStartBehavior = DragStartBehavior.start,
    this.materialTapTargetSize,
    this.thumbIcon,
    this.trackOutlineColor,
    this.trackColor,
    this.thumbColor,
    this.onInactiveThumbImageError,
    this.inactiveThumbImage,
    this.onActiveThumbImageError,
    this.activeThumbImage,
    this.inactiveTrackColor,
    this.inactiveThumbColor,
    this.activeTrackColor,
    this.activeThumbColor,
    this.activeColor,
    super.key,
  }) : _adaptive = true;

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? activeThumbColor;
  final Color? activeTrackColor;
  final Color? inactiveThumbColor;
  final Color? inactiveTrackColor;
  final ImageProvider? activeThumbImage;
  final ImageErrorListener? onActiveThumbImageError;
  final ImageProvider? inactiveThumbImage;
  final ImageErrorListener? onInactiveThumbImageError;
  final WidgetStateProperty<Color?>? thumbColor;
  final WidgetStateProperty<Color?>? trackColor;
  final WidgetStateProperty<Color?>? trackOutlineColor;
  final WidgetStateProperty<Icon?>? thumbIcon;
  final MaterialTapTargetSize? materialTapTargetSize;
  final DragStartBehavior dragStartBehavior;
  final MouseCursor? mouseCursor;
  final WidgetStateProperty<Color?>? overlayColor;
  final double? splashRadius;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;
  final bool autofocus;
  final Color? tileColor;
  final Widget? title;
  final Widget? subtitle;
  final bool? isThreeLine;
  final bool? dense;
  final EdgeInsetsGeometry? contentPadding;
  final Widget? secondary;
  final bool selected;
  final ListTileControlAffinity? controlAffinity;
  final ShapeBorder? shape;
  final Color? selectedTileColor;
  final VisualDensity? visualDensity;
  final double? horizontalTitleGap;
  final double? minVerticalPadding;
  final double? minLeadingWidth;
  final double? minTileHeight;
  final Color? hoverColor;
  final bool internalAddSemanticForOnTap;
  final bool? applyCupertinoTheme;
  final bool _adaptive;

  @override
  Widget build(BuildContext context) {
    final onChanged = AppHapticFeedback.wrapValueChanged<bool>(this.onChanged);
    return Material(
      type: MaterialType.transparency,
      child: _adaptive
          ? SwitchListTile.adaptive(
              enableFeedback: false,
              value: value,
              onChanged: onChanged,
              activeColor: activeColor,
              activeThumbColor: activeThumbColor,
              activeTrackColor: activeTrackColor,
              inactiveThumbColor: inactiveThumbColor,
              inactiveTrackColor: inactiveTrackColor,
              activeThumbImage: activeThumbImage,
              onActiveThumbImageError: onActiveThumbImageError,
              inactiveThumbImage: inactiveThumbImage,
              onInactiveThumbImageError: onInactiveThumbImageError,
              thumbColor: thumbColor,
              trackColor: trackColor,
              trackOutlineColor: trackOutlineColor,
              thumbIcon: thumbIcon,
              materialTapTargetSize: materialTapTargetSize,
              dragStartBehavior: dragStartBehavior,
              mouseCursor: mouseCursor,
              overlayColor: overlayColor,
              splashRadius: splashRadius,
              focusNode: focusNode,
              onFocusChange: onFocusChange,
              autofocus: autofocus,
              applyCupertinoTheme: applyCupertinoTheme,
              tileColor: tileColor,
              title: title,
              subtitle: subtitle,
              isThreeLine: isThreeLine,
              dense: dense,
              contentPadding: contentPadding,
              secondary: secondary,
              selected: selected,
              controlAffinity: controlAffinity,
              shape: shape,
              selectedTileColor: selectedTileColor,
              visualDensity: visualDensity,
              horizontalTitleGap: horizontalTitleGap,
              minVerticalPadding: minVerticalPadding,
              minLeadingWidth: minLeadingWidth,
              minTileHeight: minTileHeight,
              hoverColor: hoverColor,
              internalAddSemanticForOnTap: internalAddSemanticForOnTap,
            )
          : SwitchListTile(
              internalAddSemanticForOnTap: internalAddSemanticForOnTap,
              hoverColor: hoverColor,
              minTileHeight: minTileHeight,
              minLeadingWidth: minLeadingWidth,
              minVerticalPadding: minVerticalPadding,
              horizontalTitleGap: horizontalTitleGap,
              visualDensity: visualDensity,
              selectedTileColor: selectedTileColor,
              shape: shape,
              controlAffinity: controlAffinity,
              selected: selected,
              secondary: secondary,
              contentPadding: contentPadding,
              dense: dense,
              isThreeLine: isThreeLine,
              title: title,
              subtitle: subtitle,
              tileColor: tileColor,
              autofocus: autofocus,
              onFocusChange: onFocusChange,
              focusNode: focusNode,
              splashRadius: splashRadius,
              overlayColor: overlayColor,
              mouseCursor: mouseCursor,
              dragStartBehavior: dragStartBehavior,
              materialTapTargetSize: materialTapTargetSize,
              thumbIcon: thumbIcon,
              trackOutlineColor: trackOutlineColor,
              trackColor: trackColor,
              thumbColor: thumbColor,
              onInactiveThumbImageError: onInactiveThumbImageError,
              inactiveThumbImage: inactiveThumbImage,
              onActiveThumbImageError: onActiveThumbImageError,
              activeThumbImage: activeThumbImage,
              inactiveTrackColor: inactiveTrackColor,
              inactiveThumbColor: inactiveThumbColor,
              activeTrackColor: activeTrackColor,
              activeThumbColor: activeThumbColor,
              activeColor: activeColor,
              onChanged: onChanged,
              value: value,
              enableFeedback: false,
            ),
    );
  }
}
