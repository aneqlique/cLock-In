import 'package:flutter/material.dart';
import '../../core/config/theme.dart';

/// Themed yes/no confirmation. Returns true only when the user confirms.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (dctx) {
      final cs = dctx.cs;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, 44),
              backgroundColor: destructive ? cs.error : cs.primary,
              foregroundColor: destructive ? cs.onError : cs.onPrimary,
            ),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return res == true;
}

void showAppSnack(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
    ),
  );
}

/// Turns "Exception: Failed to ... 400 {"message":"..."}" into something readable.
String friendlyError(Object e) {
  final s = e.toString().replaceFirst('Exception: ', '');
  if (s.contains('E11000')) {
    if (s.contains('email')) return 'That email is already registered.';
    if (s.contains('username')) return 'That username is taken.';
  }
  final m = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(s);
  if (m != null) return m.group(1)!;
  if (s.contains('SocketException') || s.contains('Connection refused')) {
    return "Can't reach the server. Check your connection and try again.";
  }
  return s;
}
