import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomSnackbar {
  /// Shows a floating Snackbar from the top of the screen.
  static void show(
    BuildContext context, {
    required String message,
    Color backgroundColor = AppTheme.primaryGold,
    Color textColor = Colors.black,
    IconData? icon,
    bool isError = false,
    bool isSuccess = false,
  }) {
    Color bg = backgroundColor;
    Color textCol = textColor;
    IconData iconData = icon ?? Icons.info_outline_rounded;

    if (isError) {
      bg = AppTheme.errorRed;
      textCol = Colors.white;
      iconData = icon ?? Icons.error_outline_rounded;
    } else if (isSuccess) {
      bg = AppTheme.successGreen;
      textCol = Colors.white;
      iconData = icon ?? Icons.check_circle_rounded;
    }

    final double screenHeight = MediaQuery.of(context).size.height;
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    // Clear current snackbars to prevent queuing
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: textCol, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textCol,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.up,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.border, width: 0.5),
        ),
        // Push the snackbar to the top of the screen
        margin: EdgeInsets.only(
          top: statusBarHeight + 16,
          bottom: screenHeight - statusBarHeight - 100,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
