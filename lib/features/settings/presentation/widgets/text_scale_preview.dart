import 'package:flutter/material.dart';

import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';

/// معاينة حية لمقياس النص — تُستخدم في `display_settings.dart` لعرض
/// أثر [scale] الحالي فوراً على نص واقعي (عنوان + جملة وصفية) قبل أن
/// يُطبَّق [TextScaleGuard.userScale] على شجرة التطبيق كاملها، بحيث
/// يرى المستخدم النتيجة النهائية دون الحاجة لمغادرة شاشة الإعدادات
/// نفسها.
///
/// ⚠️ مكوّن عرض بحت **لا يعتمد على [TextScaleGuard]/`MediaQuery`
/// المحيطة** عمداً — يُطبِّق [scale] مباشرة عبر `MediaQuery` محلية
/// مُغلَّفة حول محتواه فقط (`_buildScaledPreview`)، لأن المعاينة يجب
/// أن تعكس [scale] المُقترَح *قبل* حفظه في `TextScaleCubit` (أثناء
/// السحب على شريط التمرير مثلاً)، وليس القيمة المحفوظة فعلياً التي
/// تُطبَّق على بقية الشاشة نفسها (`display_settings.dart` بأكملها) في
/// آن واحد — لو اعتمدت هذه البطاقة على `MediaQuery.of(context)` العادية
/// لتضاعف التكبير مرتين على السحب المباشر.
class TextScalePreview extends StatelessWidget {
  const TextScalePreview({required this.scale, super.key});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AvahiSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: AvahiRadius.radiusMd,
        border: Border.all(color: colors.outline),
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'تسجيل حضور اليوم',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
            ),
            const SizedBox(height: AvahiSpacing.xxs),
            Text(
              'هكذا سيبدو حجم النص في كل شاشات التطبيق.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
