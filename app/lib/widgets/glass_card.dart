import 'package:flutter/material.dart';
import '../theme.dart';

/// Glass Card - Frosted glass container widget used throughout the app
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool elevated;
  final VoidCallback? onTap;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
    this.elevated = false,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = elevated
        ? LaconicTheme.glassCardElevated(radius: borderRadius)
        : LaconicTheme.glassCard(radius: borderRadius);

    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: border != null
          ? decoration.copyWith(border: border)
          : decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(padding: padding, child: child),
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}

extension BoxDecorationCopyWith on BoxDecoration {
  BoxDecoration copyWith({Border? border}) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius,
      gradient: gradient,
      boxShadow: boxShadow,
      border: border ?? this.border,
    );
  }
}
