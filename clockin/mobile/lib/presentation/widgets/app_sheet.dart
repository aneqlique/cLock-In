import 'package:flutter/material.dart';
import '../../core/config/theme.dart';

/// Standard bottom-sheet layout: a "✕ · title · action" header, a scrolling
/// body and an optional sticky bottom bar that stays above the keyboard.
class AppSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool actionLoading;
  final Widget? bottom;
  final VoidCallback? onClose;

  const AppSheet({
    super.key,
    required this.title,
    required this.children,
    this.actionLabel,
    this.onAction,
    this.actionLoading = false,
    this.bottom,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            title: title,
            onClose: onClose ?? () => Navigator.maybePop(context),
            actionLabel: actionLabel,
            onAction: onAction,
            actionLoading: actionLoading,
          ),
          Divider(color: cs.outlineVariant.withValues(alpha: 0.6)),
          Flexible(
            // Tapping outside a field dismisses the keyboard.
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
          if (bottom != null)
            Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + (insets > 0 ? 0 : MediaQuery.paddingOf(context).bottom)),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)))),
              child: bottom,
            ),
        ],
      ),
    );
  }
}

/// "✕ · title · action" row used at the top of sheets.
class SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final IconData closeIcon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool actionLoading;
  final List<Widget> extraActions;

  const SheetHeader({
    super.key,
    required this.title,
    required this.onClose,
    this.closeIcon = Icons.close_rounded,
    this.actionLabel,
    this.onAction,
    this.actionLoading = false,
    this.extraActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          IconButton(tooltip: 'Close', icon: Icon(closeIcon), onPressed: onClose),
          Expanded(
            child: Text(title, textAlign: TextAlign.center, style: context.tt.titleMedium),
          ),
          ...extraActions,
          if (actionLabel != null)
            SizedBox(
              width: 72,
              child: actionLoading
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                  : TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(minimumSize: const Size(64, 40)),
                      child: Text(actionLabel!, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800)),
                    ),
            )
          else if (extraActions.isEmpty)
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Rounded container grouping related controls inside a sheet.
class SheetSection extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SheetSection({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cs.brightness == Brightness.dark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: child,
    );
  }
}
