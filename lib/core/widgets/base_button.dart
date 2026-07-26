import 'package:flutter/material.dart';

class BaseButton extends StatelessWidget {
  final String label;
  final String semanticLabel;
  final String? hint;
  final VoidCallback? onPressed;
  final bool isEmergency;
  final double height;
  final double borderRadius;
  final Widget? icon;
  final Gradient? gradient;

  const BaseButton({
    super.key,
    required this.label,
    required this.semanticLabel,
    this.hint,
    this.onPressed,
    this.isEmergency = false,
    this.height = 56,
    this.borderRadius = 16,
    this.icon,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = isEmergency
        ? theme.colorScheme.error
        : theme.colorScheme.secondary;

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: gradient != null ? Colors.transparent : backgroundColor,
      foregroundColor: Colors.white,
      shadowColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );

    Widget buttonChild = icon != null
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon!,
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        : Text(
            label,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          );

    Widget button = ElevatedButton(
      style: buttonStyle,
      onPressed: onPressed,
      child: buttonChild,
    );

    if (gradient != null) {
      button = DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed != null ? gradient : null,
          color: onPressed == null
              ? theme.disabledColor.withValues(alpha: 0.12)
              : null,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: button,
      );
    }

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      hint: hint,
      excludeSemantics: true,
      child: SizedBox(width: double.infinity, height: height, child: button),
    );
  }
}
