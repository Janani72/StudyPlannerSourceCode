import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool glass;
  final bool hasShadow;
  final double? elevation;
  final Color? backgroundColor;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.glass = false,
    this.hasShadow = true,
    this.elevation,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Decoration decoration;

    if (glass) {
      decoration = BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: hasShadow ? AppTheme.softShadow : null,
      );
    } else {
      decoration = BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: hasShadow
            ? (elevation != null
            ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06 * (elevation! / 2)),
            blurRadius: elevation! * 2,
            spreadRadius: 0,
            offset: Offset(0, elevation! / 2),
          )
        ]
            : AppTheme.softShadow)
            : null,
      );
    }

    final widget = Container(
      decoration: decoration,
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: widget,
      );
    }

    return widget;
  }
}