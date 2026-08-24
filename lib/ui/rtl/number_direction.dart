import 'package:flutter/material.dart';

/// يضمن أن **الأرقام تبقى دائماً باتجاه LTR** حتى داخل سياق نص عربي RTL،
/// وهو سلوك القراءة الطبيعي المتوقع للأرقام (١٢٣ أو 123) بصرف النظر عن
/// اتجاه الجملة المحيطة بها.
///
/// السبب: عند عرض رقم مثل "0791234567" داخل جملة عربية RTL دون معالجة،
/// قد ينعكس ترتيب أجزاء الرقم بصرياً (خصوصاً حين يُدمج مع نص/رموز أخرى
/// كالفواصل أو الأقواس). لتفادي ذلك، نلفّ الرقم بعلامات Unicode
/// الاتجاهية الضمنية (Embedding) لإجباره على البقاء LTR بمعزل عن السياق.
abstract class AvahiNumberDirection {
  /// علامة Unicode لبدء تضمين LTR صريح (LRE - Left-to-Right Embedding).
  static const String _lre = '\u202A';

  /// علامة Unicode لإنهاء التضمين الاتجاهي (PDF - Pop Directional
  /// Formatting).
  static const String _pdf = '\u202C';

  /// يلفّ أي نص رقمي (أو نص يحتوي أرقاماً/رموزاً كالهاتف أو المعرّفات)
  /// بعلامات Unicode لضمان بقائه LTR دائماً بصرف النظر عن اتجاه النص
  /// المحيط به.
  ///
  /// ```dart
  /// Text(AvahiNumberDirection.forceLtr('+964 750 123 4567'))
  /// ```
  static String forceLtr(String value) => '$_lre$value$_pdf';

  /// نسخة مخصصة للأرقام العشرية/الإحصائية (تُبقيها LTR وتُنسّق الفاصلة
  /// العشرية بشكل ثابت بغض النظر عن لغة الجهاز).
  static String forceLtrNumber(num value) => forceLtr(value.toString());
}

/// Widget جاهز لعرض نص رقمي (أرقام، هواتف، معرّفات، تواريخ رقمية) مضموناً
/// أن يبقى LTR داخل أي سياق RTL، مبني فوق [Text] القياسي.
///
/// ```dart
/// AvahiNumberText('+964 750 123 4567', style: theme.textTheme.bodyMedium)
/// ```
class AvahiNumberText extends StatelessWidget {
  const AvahiNumberText(
    this.value, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  /// القيمة الرقمية أو النصية المطلوب عرضها بشكل LTR ثابت.
  final String value;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    );
  }
}
