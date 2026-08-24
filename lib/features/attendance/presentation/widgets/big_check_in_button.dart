import 'package:flutter/material.dart';

import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_button.dart';

/// زر تسجيل الحضور/الانصراف البارز — أكثر عنصر تفاعل يومي تكراراً في
/// كامل التطبيق لدور العامل الميداني، لذا مبني كنسخة مكبّرة من
/// [AvahiButton] بحجم [AvahiButtonSize.large] وعرض كامل دوماً، مع نص
/// ثانوي اختياري تحته (مثال: وقت آخر تسجيل حضور).
///
/// مكوّن عرض بحت — لا يحمل أي منطق GPS/QR فعلي؛ `check_in_screen.dart`
/// هو من يقرر [label]/[icon]/[onPressed] المناسبة حسب حالة
/// `AttendanceCubit` الحالية.
class BigCheckInButton extends StatelessWidget {
  const BigCheckInButton({
    required this.label,
    super.key,
    this.subtitle,
    this.icon = Icons.fingerprint,
    this.onPressed,
    this.isLoading = false,
    this.isDanger = false,
  });

  final String label;

  /// نص ثانوي صغير يُعرض أسفل الزر مباشرة (مثال: "آخر حضور: 07:42 ص").
  final String? subtitle;

  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// عند `true`، يُستخدم نمط [AvahiButtonVariant.danger] بدل الأساسي —
  /// مخصص لزر "تسجيل الانصراف" (فعل ينهي جلسة العمل، وليس فعلاً
  /// إيجابياً محايداً كتسجيل الحضور).
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AvahiButton(
          label: label,
          icon: icon,
          size: AvahiButtonSize.large,
          isFullWidth: true,
          isLoading: isLoading,
          variant: isDanger ? AvahiButtonVariant.danger : AvahiButtonVariant.primary,
          onPressed: onPressed,
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: AvahiSpacing.xs),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
