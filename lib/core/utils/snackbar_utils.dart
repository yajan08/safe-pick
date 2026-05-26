import 'package:flutter/material.dart';
import '../widgets/custom_snackbar.dart';

class SnackBarUtils {
  static void showSuccess(BuildContext context, String message) {
    CustomSnackbar.show(
      context,
      message: message,
      isSuccess: true,
    );
  }

  static void showError(BuildContext context, String message) {
    CustomSnackbar.show(
      context,
      message: message,
      isError: true,
    );
  }

  static void showInfo(BuildContext context, String message) {
    CustomSnackbar.show(
      context,
      message: message,
    );
  }
}

