import 'package:flutter/material.dart';
import '../../app/theme/app_spacing.dart';

/// Standard Material 3 card container — rounded corners, subtle border, smooth hover & click states.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.onLongPress,
    this.margin,
    this.clipBehavior = Clip.antiAlias,
    this.color,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? margin;
  final Clip clipBehavior;
  final Color? color;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardRadius = borderRadius ?? BorderRadius.circular(AppRadius.card);

    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      content = InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: cardRadius,
        hoverColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        splashColor: theme.colorScheme.onSurface.withValues(alpha: 0.10),
        highlightColor: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        child: content,
      );
    }

    return Card(
      color: color,
      margin: margin ?? EdgeInsets.zero,
      clipBehavior: clipBehavior,
      shape: RoundedRectangleBorder(
        borderRadius: cardRadius,
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: content,
    );
  }
}
