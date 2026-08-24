/// امتدادات مساعدة على [String] مستخدمة عبر التطبيق.
extension StringX on String {
  /// يُعيد صحيح إذا كانت السلسلة فارغة بعد إزالة الفراغات الطرفية.
  bool get isBlank => trim().isEmpty;

  /// عكس [isBlank].
  bool get isNotBlank => !isBlank;

  /// يجعل الحرف الأول كبيراً (مفيد أساساً للنصوص الإنجليزية).
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// يقتصّ النص إلى [maxLength] حرفاً ويضيف "..." عند القص.
  String truncate(int maxLength, {String ellipsis = '…'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  /// يُعيد null إذا كانت السلسلة فارغة، وإلا يُعيدها كما هي — مفيد
  /// لتحويل حقول نصية فارغة من نماذج الإدخال إلى قيم قابلة لـ null
  /// قبل إرسالها إلى قاعدة البيانات.
  String? get nullIfBlank => isBlank ? null : this;

  /// يتحقق مما إذا كانت السلسلة تحتوي فقط على أرقام.
  bool get isNumericOnly => RegExp(r'^[0-9]+$').hasMatch(this);

  /// يُخفي جزءاً من نص حساس (مثال: بريد إلكتروني) للعرض في السجلات:
  /// "ahmad@example.com" → "ah***@example.com".
  String get maskedForLogs {
    if (length <= 4) return '***';
    final int atIndex = indexOf('@');
    if (atIndex > 2) {
      return '${substring(0, 2)}***${substring(atIndex)}';
    }
    return '${substring(0, 2)}***${substring(length - 2)}';
  }
}
