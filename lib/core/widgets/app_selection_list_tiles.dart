// Mirrors Flutter's selection tile APIs; delegated property docs stay in SDK.
// ignore_for_file: deprecated_member_use, public_member_api_docs

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// App-standard [CheckboxListTile] with Material feedback disabled centrally.
class AppCheckboxListTile extends StatelessWidget {
  /// Creates an app checkbox list tile.
  const AppCheckboxListTile({
    required this.value,
    required this.onChanged,
    this.mouseCursor,
    this.activeColor,
    this.fillColor,
    this.checkColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.visualDensity,
    this.focusNode,
    this.autofocus = false,
    this.shape,
    this.side,
    this.isError = false,
    this.enabled,
    this.tileColor,
    this.title,
    this.subtitle,
    this.isThreeLine,
    this.dense,
    this.secondary,
    this.selected = false,
    this.controlAffinity,
    this.contentPadding,
    this.tristate = false,
    this.checkboxShape,
    this.selectedTileColor,
    this.onFocusChange,
    this.horizontalTitleGap,
    this.minVerticalPadding,
    this.minLeadingWidth,
    this.minTileHeight,
    this.checkboxSemanticLabel,
    this.checkboxScaleFactor = 1.0,
    this.titleAlignment,
    this.internalAddSemanticForOnTap = false,
    super.key,
  });

  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final MouseCursor? mouseCursor;
  final Color? activeColor;
  final WidgetStateProperty<Color?>? fillColor;
  final Color? checkColor;
  final Color? hoverColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final double? splashRadius;
  final MaterialTapTargetSize? materialTapTargetSize;
  final VisualDensity? visualDensity;
  final FocusNode? focusNode;
  final bool autofocus;
  final ShapeBorder? shape;
  final BorderSide? side;
  final bool isError;
  final bool? enabled;
  final Color? tileColor;
  final Widget? title;
  final Widget? subtitle;
  final bool? isThreeLine;
  final bool? dense;
  final Widget? secondary;
  final bool selected;
  final ListTileControlAffinity? controlAffinity;
  final EdgeInsetsGeometry? contentPadding;
  final bool tristate;
  final OutlinedBorder? checkboxShape;
  final Color? selectedTileColor;
  final ValueChanged<bool>? onFocusChange;
  final double? horizontalTitleGap;
  final double? minVerticalPadding;
  final double? minLeadingWidth;
  final double? minTileHeight;
  final String? checkboxSemanticLabel;
  final double checkboxScaleFactor;
  final ListTileTitleAlignment? titleAlignment;
  final bool internalAddSemanticForOnTap;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      enableFeedback: false,
      value: value,
      onChanged: onChanged,
      mouseCursor: mouseCursor,
      activeColor: activeColor,
      fillColor: fillColor,
      checkColor: checkColor,
      hoverColor: hoverColor,
      overlayColor: overlayColor,
      splashRadius: splashRadius,
      materialTapTargetSize: materialTapTargetSize,
      visualDensity: visualDensity,
      focusNode: focusNode,
      autofocus: autofocus,
      shape: shape,
      side: side,
      isError: isError,
      enabled: enabled,
      tileColor: tileColor,
      title: title,
      subtitle: subtitle,
      isThreeLine: isThreeLine,
      dense: dense,
      secondary: secondary,
      selected: selected,
      controlAffinity: controlAffinity,
      contentPadding: contentPadding,
      tristate: tristate,
      checkboxShape: checkboxShape,
      selectedTileColor: selectedTileColor,
      onFocusChange: onFocusChange,
      horizontalTitleGap: horizontalTitleGap,
      minVerticalPadding: minVerticalPadding,
      minLeadingWidth: minLeadingWidth,
      minTileHeight: minTileHeight,
      checkboxSemanticLabel: checkboxSemanticLabel,
      checkboxScaleFactor: checkboxScaleFactor,
      titleAlignment: titleAlignment,
      internalAddSemanticForOnTap: internalAddSemanticForOnTap,
    );
  }
}

/// App-standard [RadioListTile] with Material feedback disabled centrally.
class AppRadioListTile<T> extends StatelessWidget {
  /// Creates an app radio list tile.
  const AppRadioListTile({
    required this.value,
    this.groupValue,
    this.onChanged,
    this.mouseCursor,
    this.toggleable = false,
    this.activeColor,
    this.fillColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.title,
    this.subtitle,
    this.isThreeLine,
    this.dense,
    this.secondary,
    this.selected = false,
    this.controlAffinity,
    this.autofocus = false,
    this.contentPadding,
    this.shape,
    this.tileColor,
    this.selectedTileColor,
    this.visualDensity,
    this.focusNode,
    this.onFocusChange,
    this.horizontalTitleGap,
    this.minVerticalPadding,
    this.minLeadingWidth,
    this.minTileHeight,
    this.radioScaleFactor = 1.0,
    this.titleAlignment,
    this.enabled,
    this.internalAddSemanticForOnTap = false,
    this.radioBackgroundColor,
    this.radioSide,
    this.radioInnerRadius,
    super.key,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final MouseCursor? mouseCursor;
  final bool toggleable;
  final Color? activeColor;
  final WidgetStateProperty<Color?>? fillColor;
  final Color? hoverColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final double? splashRadius;
  final MaterialTapTargetSize? materialTapTargetSize;
  final Widget? title;
  final Widget? subtitle;
  final bool? isThreeLine;
  final bool? dense;
  final Widget? secondary;
  final bool selected;
  final ListTileControlAffinity? controlAffinity;
  final bool autofocus;
  final EdgeInsetsGeometry? contentPadding;
  final ShapeBorder? shape;
  final Color? tileColor;
  final Color? selectedTileColor;
  final VisualDensity? visualDensity;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;
  final double? horizontalTitleGap;
  final double? minVerticalPadding;
  final double? minLeadingWidth;
  final double? minTileHeight;
  final double radioScaleFactor;
  final ListTileTitleAlignment? titleAlignment;
  final bool? enabled;
  final bool internalAddSemanticForOnTap;
  final WidgetStateProperty<Color?>? radioBackgroundColor;
  final BorderSide? radioSide;
  final WidgetStateProperty<double?>? radioInnerRadius;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<T>(
      enableFeedback: false,
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      mouseCursor: mouseCursor,
      toggleable: toggleable,
      activeColor: activeColor,
      fillColor: fillColor,
      hoverColor: hoverColor,
      overlayColor: overlayColor,
      splashRadius: splashRadius,
      materialTapTargetSize: materialTapTargetSize,
      title: title,
      subtitle: subtitle,
      isThreeLine: isThreeLine,
      dense: dense,
      secondary: secondary,
      selected: selected,
      controlAffinity: controlAffinity,
      autofocus: autofocus,
      contentPadding: contentPadding,
      shape: shape,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
      visualDensity: visualDensity,
      focusNode: focusNode,
      onFocusChange: onFocusChange,
      horizontalTitleGap: horizontalTitleGap,
      minVerticalPadding: minVerticalPadding,
      minLeadingWidth: minLeadingWidth,
      minTileHeight: minTileHeight,
      radioScaleFactor: radioScaleFactor,
      titleAlignment: titleAlignment,
      enabled: enabled,
      internalAddSemanticForOnTap: internalAddSemanticForOnTap,
      radioBackgroundColor: radioBackgroundColor,
      radioSide: radioSide,
      radioInnerRadius: radioInnerRadius,
    );
  }
}

/// App-standard [SwitchListTile] with Material feedback disabled centrally.
class AppSwitchListTile extends StatelessWidget {
  /// Creates an app switch list tile.
  const AppSwitchListTile({
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
  const AppSwitchListTile.adaptive({
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
    this.applyCupertinoTheme,
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
    if (_adaptive) {
      return SwitchListTile.adaptive(
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
      );
    }

    return SwitchListTile(
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
    );
  }
}
