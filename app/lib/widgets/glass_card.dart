import 'package:flutter/material.dart';
import '../theme.dart';

/// Agoge Card - Zero-radius container widget with tonal layering
class AgogeCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final bool elevated;
  final VoidCallback? onTap;
  final Color? color;
  final bool hasBorder;

  const AgogeCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.elevated = false,
    this.onTap,
    this.color,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = LaconicTheme.agogeCard(
      color: color,
      elevated: elevated,
      hasBorder: hasBorder,
    );

    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: decoration,
      child: Padding(padding: padding, child: child),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: card,
        ),
      );
    }

    return card;
  }
}
