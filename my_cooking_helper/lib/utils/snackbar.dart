import 'package:flutter/material.dart';
import 'package:alert_info/alert_info.dart';
export 'package:alert_info/alert_info.dart' show TypeInfo, MessagePosition;

class SnackbarUtils {
  static void show(
    BuildContext context,
    String message, {
    int duration = 2000, // milliseconds
    ShapeBorder? shape,
    SnackBarAction? action,
    IconData? icon,
    Color? iconColor,
    double? elevation,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    TextStyle? textStyle,
    SnackBarBehavior? behavior,
    Color? backgroundColor,
    double? width,
    DismissDirection dismissDirection = DismissDirection.down,
  }) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, color: iconColor ?? Colors.white, size: 20),
            if (icon != null) const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                style: textStyle ?? theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: Duration(milliseconds: duration),
        backgroundColor: backgroundColor ??  theme.snackBarTheme.backgroundColor,
        shape: shape,
        action: action,
        elevation: elevation,
        margin: margin,
        padding: padding,
        behavior: behavior ?? (margin != null ? SnackBarBehavior.floating : SnackBarBehavior.fixed),
        width: width,
        dismissDirection: dismissDirection,
      ),
    );
  }

  static void alert(
    BuildContext context,
    String text, {
    TypeInfo typeInfo = TypeInfo.info,
    MessagePosition position = MessagePosition.top,
    double padding = 30.0,
    int duration = 3, //seconds
    Color? iconColor,
    Color? actionColor,
    String? action,
    void Function()? actionCallback,
    IconData? icon,
    String? title,
  }) {
    AlertInfo.show(
      context: context,
      text: text,
      position: position,
      padding: padding,
      duration: duration,
      iconColor: iconColor,
      actionColor: actionColor,
      action: action,
      actionCallback: actionCallback,
      icon: icon,
      typeInfo: typeInfo,
    );
  }
}
