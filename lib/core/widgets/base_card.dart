import 'package:flutter/material.dart';

class BaseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final String? semanticLabel;

  final Color? backgroundColor;
  final Gradient? gradient;
  final Border? border;
  final bool? isButton;
  final String? onTapHint;

  const BaseCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.semanticLabel,
    this.backgroundColor,
    this.gradient,
    this.border,
    this.isButton,
    this.onTapHint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cardDecoration = BoxDecoration(
      color: gradient == null
          ? (backgroundColor ?? theme.colorScheme.surface)
          : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(16),
      border: border,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

    Widget cardContent;

    if (onTap != null) {
      cardContent = Container(
        decoration: cardDecoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      );
    } else {
      cardContent = Container(
        decoration: cardDecoration,
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      );
    }

    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: semanticLabel != null
          ? Semantics(
              container: true,
              button: isButton,
              onTapHint: onTapHint,
              label: semanticLabel,
              excludeSemantics: true,
              child: cardContent,
            )
          : cardContent,
    );
  }
}
