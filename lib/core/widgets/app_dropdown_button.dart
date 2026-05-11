// Mirrors Flutter's dropdown APIs; delegated property docs stay in the SDK.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

/// App-standard [DropdownButton] with Material feedback disabled centrally.
class AppDropdownButton<T> extends StatelessWidget {
  /// Creates an app dropdown button.
  const AppDropdownButton({
    required this.items,
    required this.onChanged,
    this.selectedItemBuilder,
    this.value,
    this.hint,
    this.disabledHint,
    this.onTap,
    this.elevation = 8,
    this.style,
    this.underline,
    this.icon,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.iconSize = 24.0,
    this.isDense = false,
    this.isExpanded = false,
    this.itemHeight = kMinInteractiveDimension,
    this.menuWidth,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
    this.dropdownColor,
    this.menuMaxHeight,
    this.alignment = AlignmentDirectional.centerStart,
    this.borderRadius,
    this.padding,
    this.barrierDismissible = true,
    this.mouseCursor,
    this.dropdownMenuItemMouseCursor,
    super.key,
  });

  final List<DropdownMenuItem<T>>? items;
  final DropdownButtonBuilder? selectedItemBuilder;
  final T? value;
  final Widget? hint;
  final Widget? disabledHint;
  final ValueChanged<T?>? onChanged;
  final VoidCallback? onTap;
  final int elevation;
  final TextStyle? style;
  final Widget? underline;
  final Widget? icon;
  final Color? iconDisabledColor;
  final Color? iconEnabledColor;
  final double iconSize;
  final bool isDense;
  final bool isExpanded;
  final double? itemHeight;
  final double? menuWidth;
  final Color? focusColor;
  final FocusNode? focusNode;
  final bool autofocus;
  final Color? dropdownColor;
  final double? menuMaxHeight;
  final AlignmentGeometry alignment;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool barrierDismissible;
  final MouseCursor? mouseCursor;
  final MouseCursor? dropdownMenuItemMouseCursor;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      enableFeedback: false,
      items: items,
      selectedItemBuilder: selectedItemBuilder,
      value: value,
      hint: hint,
      disabledHint: disabledHint,
      onChanged: onChanged,
      onTap: onTap,
      elevation: elevation,
      style: style,
      underline: underline,
      icon: icon,
      iconDisabledColor: iconDisabledColor,
      iconEnabledColor: iconEnabledColor,
      iconSize: iconSize,
      isDense: isDense,
      isExpanded: isExpanded,
      itemHeight: itemHeight,
      menuWidth: menuWidth,
      focusColor: focusColor,
      focusNode: focusNode,
      autofocus: autofocus,
      dropdownColor: dropdownColor,
      menuMaxHeight: menuMaxHeight,
      alignment: alignment,
      borderRadius: borderRadius,
      padding: padding,
      barrierDismissible: barrierDismissible,
      mouseCursor: mouseCursor,
      dropdownMenuItemMouseCursor: dropdownMenuItemMouseCursor,
    );
  }
}

/// App-standard [DropdownButtonFormField] with feedback disabled centrally.
class AppDropdownButtonFormField<T> extends StatelessWidget {
  /// Creates an app dropdown form field.
  const AppDropdownButtonFormField({
    required this.items,
    required this.onChanged,
    this.selectedItemBuilder,
    this.initialValue,
    this.hint,
    this.disabledHint,
    this.onTap,
    this.elevation = 8,
    this.style,
    this.icon,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.iconSize = 24.0,
    this.isDense = true,
    this.isExpanded = false,
    this.itemHeight,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
    this.dropdownColor,
    this.decoration,
    this.onSaved,
    this.validator,
    this.errorBuilder,
    this.forceErrorText,
    this.autovalidateMode,
    this.menuMaxHeight,
    this.alignment = AlignmentDirectional.centerStart,
    this.borderRadius,
    this.padding,
    this.barrierDismissible = true,
    this.mouseCursor,
    this.dropdownMenuItemMouseCursor,
    super.key,
  });

  final List<DropdownMenuItem<T>>? items;
  final DropdownButtonBuilder? selectedItemBuilder;
  final T? initialValue;
  final Widget? hint;
  final Widget? disabledHint;
  final ValueChanged<T?>? onChanged;
  final VoidCallback? onTap;
  final int elevation;
  final TextStyle? style;
  final Widget? icon;
  final Color? iconDisabledColor;
  final Color? iconEnabledColor;
  final double iconSize;
  final bool isDense;
  final bool isExpanded;
  final double? itemHeight;
  final Color? focusColor;
  final FocusNode? focusNode;
  final bool autofocus;
  final Color? dropdownColor;
  final InputDecoration? decoration;
  final FormFieldSetter<T>? onSaved;
  final FormFieldValidator<T>? validator;
  final FormFieldErrorBuilder? errorBuilder;
  final String? forceErrorText;
  final AutovalidateMode? autovalidateMode;
  final double? menuMaxHeight;
  final AlignmentGeometry alignment;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool barrierDismissible;
  final MouseCursor? mouseCursor;
  final MouseCursor? dropdownMenuItemMouseCursor;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      enableFeedback: false,
      items: items,
      selectedItemBuilder: selectedItemBuilder,
      initialValue: initialValue,
      hint: hint,
      disabledHint: disabledHint,
      onChanged: onChanged,
      onTap: onTap,
      elevation: elevation,
      style: style,
      icon: icon,
      iconDisabledColor: iconDisabledColor,
      iconEnabledColor: iconEnabledColor,
      iconSize: iconSize,
      isDense: isDense,
      isExpanded: isExpanded,
      itemHeight: itemHeight,
      focusColor: focusColor,
      focusNode: focusNode,
      autofocus: autofocus,
      dropdownColor: dropdownColor,
      decoration: decoration,
      onSaved: onSaved,
      validator: validator,
      errorBuilder: errorBuilder,
      forceErrorText: forceErrorText,
      autovalidateMode: autovalidateMode,
      menuMaxHeight: menuMaxHeight,
      alignment: alignment,
      borderRadius: borderRadius,
      padding: padding,
      barrierDismissible: barrierDismissible,
      mouseCursor: mouseCursor,
      dropdownMenuItemMouseCursor: dropdownMenuItemMouseCursor,
    );
  }
}
