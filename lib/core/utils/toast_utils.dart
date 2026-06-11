import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class ToastUtils {
  static OverlayEntry? _currentToast;

  /// Shows a floating, translucent toast in the center/bottom of the screen for 2 seconds.
  static void showToast(BuildContext context, String message, {bool isError = false}) {
    if (_currentToast != null) {
      _currentToast!.remove();
      _currentToast = null;
    }

    final overlay = Overlay.of(context);

    _currentToast = OverlayEntry(
      builder: (context) {
        return Positioned(
          bottom: MediaQuery.of(context).size.height * 0.15,
          left: 32,
          right: 32,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: isError
                      ? AppTheme.errorRed.withValues(alpha: 0.9)
                      : Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ).animate().fade(duration: 200.ms).slideY(begin: 0.2, end: 0, duration: 200.ms, curve: Curves.easeOutCubic),
            ),
          ),
        );
      },
    );

    overlay.insert(_currentToast!);

    Future.delayed(const Duration(seconds: 2), () {
      if (_currentToast != null) {
        _currentToast!.remove();
        _currentToast = null;
      }
    });
  }
}
