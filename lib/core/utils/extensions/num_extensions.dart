/// امتدادات مساعدة على [num] لاستخدامات شائعة في الواجهة (Padding،
/// SizedBox) ضمن أنماط `flutter` الشائعة.
extension NumX on num {
  /// يُقيّد القيمة ضمن [min]/[max] (اختصار مقروء لـ `clamp`).
  num limitTo(num min, num max) => clamp(min, max);

  /// يحوّل نسبة مئوية (0-100) إلى قيمة عشرية (0.0-1.0).
  double get asRatio => this / 100;
}
