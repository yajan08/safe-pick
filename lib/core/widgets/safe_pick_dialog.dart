import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A premium, unified dialog widget for SafePick.
/// Enforces visual layout consistency, pixel-perfect spacing, and rounded geometry.
class SafePickDialog extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? content;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final Color? primaryActionColor;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool isDestructive;
  final bool isPrimaryActionEnabled;
  final Widget? titleIcon;

  const SafePickDialog({
    super.key,
    required this.title,
    this.description,
    this.content,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.primaryActionColor,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.isDestructive = false,
    this.isPrimaryActionEnabled = true,
    this.titleIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Resolve primary action color
    final Color buttonColor = primaryActionColor ?? 
        (isDestructive ? AppTheme.errorRed : AppTheme.primaryGold);

    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: (isDestructive ? AppTheme.errorRed : AppTheme.border).withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (titleIcon != null) ...[
                  titleIcon!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDestructive ? AppTheme.errorRed : AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ) ?? TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDestructive ? AppTheme.errorRed : AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Description Copy
            if (description != null) ...[
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ) ?? const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
            
            // Custom Inner Content
            if (content != null) ...[
              if (description != null) const SizedBox(height: 16),
              content!,
            ],
            
            const SizedBox(height: 24),
            
            // Action Buttons Row/Column
            _buildActions(context, buttonColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, Color buttonColor) {
    final hasSecondary = secondaryActionLabel != null || onSecondaryAction != null;
    final hasPrimary = primaryActionLabel != null && onPrimaryAction != null;

    final secondaryLabel = secondaryActionLabel ?? 'Cancel';
    final cancelCallback = onSecondaryAction ?? () => Navigator.of(context).pop();

    if (hasPrimary && hasSecondary) {
      // Side-by-side balanced row of actions (Option A - clean, symmetric UI)
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: cancelCallback,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: AppTheme.border, width: 1.2),
                foregroundColor: AppTheme.textSecondary,
              ),
              child: Text(secondaryLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: isPrimaryActionEnabled ? onPrimaryAction : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: buttonColor,
                disabledBackgroundColor: buttonColor.withValues(alpha: 0.3),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(primaryActionLabel!, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
    } else if (hasPrimary) {
      // Only Primary Action (e.g. status/error notification confirmations)
      return ElevatedButton(
        onPressed: isPrimaryActionEnabled ? onPrimaryAction : null,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: buttonColor,
          disabledBackgroundColor: buttonColor.withValues(alpha: 0.3),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(primaryActionLabel!, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
    } else if (hasSecondary) {
      // Only Secondary Action (e.g. CANCEL option dialogs)
      return OutlinedButton(
        onPressed: cancelCallback,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppTheme.border, width: 1.2),
          foregroundColor: AppTheme.textSecondary,
        ),
        child: Text(secondaryLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
