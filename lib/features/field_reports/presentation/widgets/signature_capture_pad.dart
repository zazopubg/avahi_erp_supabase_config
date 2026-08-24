import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_button.dart';

/// لوحة التقاط توقيع رقمي تفاعلية — غلاف فوق حزمة `signature`
/// (`SignatureController`/`Signature`)، تُستخدم مرتين في
/// `report_signature_screen.dart`: توقيع المشرف (إلزامي) وتوقيع
/// العميل (اختياري)، كل واحدة بـ [SignatureController] مستقل خاص بها.
///
/// ودجة عرض بحتة: لا تستدعي أي `UseCase`/تخزين بنفسها؛
/// `report_signature_screen.dart` يقرأ بايتات التوقيع النهائية عبر
/// [controller] (`controller.toPngBytes()`) عند الضغط على "تقديم".
class SignatureCapturePad extends StatelessWidget {
  const SignatureCapturePad({
    required this.controller,
    required this.title,
    super.key,
    this.isRequired = false,
    this.helperText,
  });

  final SignatureController controller;
  final String title;
  final bool isRequired;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              isRequired ? '$title *' : '$title (اختياري)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: controller,
              builder: (_, __) => TextButton.icon(
                onPressed: controller.isNotEmpty ? controller.clear : null,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('مسح'),
              ),
            ),
          ],
        ),
        if (helperText != null) ...<Widget>[
          const SizedBox(height: AvahiSpacing.xxs),
          Text(
            helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: AvahiSpacing.xs),
        Container(
          height: 180,
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: AvahiRadius.radiusMd,
            color: colors.surface,
          ),
          child: ClipRRect(
            borderRadius: AvahiRadius.radiusMd,
            child: Signature(
              controller: controller,
              backgroundColor: colors.surface,
            ),
          ),
        ),
      ],
    );
  }
}

/// عنصر أدوات صغير: زر "مسح الكل" يُعيد ضبط توقيعين معاً (مشرف/عميل) —
/// `report_signature_screen.dart` يستخدمه فوق لوحتَي التوقيع.
class SignaturePadClearAllButton extends StatelessWidget {
  const SignaturePadClearAllButton({required this.onClearAll, super.key});

  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return AvahiButton(
      label: 'مسح كل التوقيعات',
      variant: AvahiButtonVariant.text,
      icon: Icons.delete_outline,
      onPressed: onClearAll,
    );
  }
}
