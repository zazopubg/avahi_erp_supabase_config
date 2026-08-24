import 'package:flutter/material.dart';

import '../../theme/avahi_spacing.dart';
import 'avahi_button.dart';

/// حوار (Dialog) موحّد لتطبيق Avahi بتصميم متسق: عنوان، محتوى، وصف
/// اختياري، وصف أزرار إجراءات (تأكيد/إلغاء) بنمط [AvahiButton].
///
/// مكوّن عرض بحت — لا يحتوي أي منطق عمل، فقط يُستدعى عبر [AvahiDialog.show]
/// من الشاشات التي تحتاج لعرض حوار.
class AvahiDialog extends StatelessWidget {
  const AvahiDialog({
    required this.title,
    super.key,
    this.message,
    this.content,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.isConfirmLoading = false,
  });

  final String title;

  /// نص وصفي بسيط يُعرض تحت العنوان (بديل عن [content] المخصص).
  final String? message;

  /// محتوى مخصص كامل (يُستخدم بدلاً من [message] لعرض ودجات أعقد).
  final Widget? content;

  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// عند `true`، يُعرض زر التأكيد بنمط [AvahiButtonVariant.danger].
  final bool isDestructive;

  final bool isConfirmLoading;

  /// طريقة مختصرة لعرض الحوار عبر `showDialog`.
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? message,
    Widget? content,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
    bool barrierDismissible = true,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) => AvahiDialog(
        title: title,
        message: message,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: content ?? (message != null ? Text(message!) : null),
      actionsPadding: const EdgeInsets.fromLTRB(
        AvahiSpacing.md,
        0,
        AvahiSpacing.md,
        AvahiSpacing.md,
      ),
      actions: <Widget>[
        if (cancelLabel != null)
          AvahiButton(
            label: cancelLabel!,
            variant: AvahiButtonVariant.text,
            onPressed: onCancel ?? () => Navigator.of(context).pop(),
          ),
        if (confirmLabel != null)
          AvahiButton(
            label: confirmLabel!,
            variant: isDestructive
                ? AvahiButtonVariant.danger
                : AvahiButtonVariant.primary,
            isLoading: isConfirmLoading,
            onPressed: onConfirm,
          ),
      ],
    );
  }
}
