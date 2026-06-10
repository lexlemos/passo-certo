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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = isEmergency 
        ? theme.colorScheme.error 
        : theme.colorScheme.secondary;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      hint: hint,
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: Colors.white,
            elevation: 0, 
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius), 
            ),
          ),
          onPressed: onPressed,
          child: icon != null 
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
                      ),
                    ),
                  ],
                )
              : Text(
                  label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 18, 
                  ),
                ),
        ),
      ),
    );
  }
}