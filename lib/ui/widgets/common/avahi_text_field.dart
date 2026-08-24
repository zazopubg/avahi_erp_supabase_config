import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// حقل نص موحّد لتطبيق Avahi — غلاف نظيف فوق [TextFormField] يطبّق
/// أنماط `InputDecorationTheme` المُعرَّفة في الثيم، مع دعم أيقونات
/// البداية/النهاية وحالة الخطأ ونص المساعدة.
///
/// مكوّن عرض بحت بلا أي منطق تحقق (Validation) عمل فعلي أو استدعاء API؛
/// يستقبل [validator] كدالة اختيارية يوفّرها المستدعي.
class AvahiTextField extends StatelessWidget {
  const AvahiTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      textAlign: textAlign,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
