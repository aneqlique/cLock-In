import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

/// The app's standard button: full-width by default, with a loading state.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.variant = AppButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onPressed = loading ? null : this.onPressed;

    Color spinnerColor;
    switch (variant) {
      case AppButtonVariant.primary:
        spinnerColor = cs.onPrimary;
      case AppButtonVariant.danger:
        spinnerColor = cs.error;
      case AppButtonVariant.secondary:
      case AppButtonVariant.ghost:
        spinnerColor = cs.onSurface;
    }

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: spinnerColor),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = FilledButton(onPressed: onPressed, child: child);
      case AppButtonVariant.secondary:
        button = OutlinedButton(onPressed: onPressed, child: child);
      case AppButtonVariant.ghost:
        button = TextButton(onPressed: onPressed, child: child);
      case AppButtonVariant.danger:
        button = OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.error,
            side: BorderSide(color: cs.error.withValues(alpha: 0.6)),
          ),
          child: child,
        );
    }

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
