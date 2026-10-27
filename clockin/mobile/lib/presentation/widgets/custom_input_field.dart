import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/config/theme.dart';

/// Themed text field used across forms.
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final int? minLines;
  final bool autofocus;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      autofocus: autofocus,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
        suffixIcon: suffix,
      ),
    );
    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [FieldLabel(label!), field],
    );
  }
}

/// Small label shown above a form field or group.
class FieldLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const FieldLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: context.tt.labelLarge?.copyWith(color: context.cs.onSurfaceVariant),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Password field with a show/hide toggle.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: _obscure,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      suffix: IconButton(
        tooltip: _obscure ? 'Show password' : 'Hide password',
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
      ),
    );
  }
}

/// A tappable time "chip" that opens the themed time picker.
class TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;
  final IconData icon;

  const TimePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon = Icons.schedule_rounded,
  });

  Future<void> _pick(BuildContext context) async {
    // Drop keyboard focus so it doesn't pop back up after the picker closes.
    FocusScope.of(context).unfocus();
    final picked = await showTimePicker(
      context: context,
      initialTime: value ?? TimeOfDay.now(),
      helpText: label.toUpperCase(),
    );
    // The dialog route restores the previous focus when it closes; clear it again.
    FocusManager.instance.primaryFocus?.unfocus();
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final isDark = cs.brightness == Brightness.dark;
    final text = value == null ? '--:--' : MaterialLocalizations.of(context)
            .formatTimeOfDay(value!, alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));
    return Semantics(
      button: true,
      label: '$label, $text',
      child: Material(
        color: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => _pick(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: context.tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Text(text, style: context.tt.titleMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
