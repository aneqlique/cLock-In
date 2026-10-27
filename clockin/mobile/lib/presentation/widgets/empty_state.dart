import 'package:flutter/material.dart';
import '../../core/config/theme.dart';
import 'custom_button.dart';

/// Friendly empty / error placeholder with an optional call-to-action.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: cs.surfaceContainerHigh, shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: context.tt.titleMedium),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: context.tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            AppButton(
              label: actionLabel!,
              icon: actionIcon,
              onPressed: onAction,
              expand: false,
              variant: AppButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }
}
