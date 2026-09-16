import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, text }

/// Unified button component — primary, secondary (outlined), text variants.
/// Minimum touch target: 52 dp height (primary), 48 dp (others).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.enabled = true,
    this.glow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool enabled;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = (enabled && !isLoading && onPressed != null)
        ? () {
            HapticFeedback.lightImpact();
            onPressed!();
          }
        : null;

    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.onPrimary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label),
            ],
          );

    return switch (variant) {
      AppButtonVariant.primary => Container(
          decoration: (enabled && glow && !isLoading)
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
                )
              : null,
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            child: child,
          ),
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
    };
  }
}
