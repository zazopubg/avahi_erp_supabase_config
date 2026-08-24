import '../constants/app_constants.dart';

/// أدوات تحقق سريعة على مستوى الواجهة (Presentation-level Validation)،
/// مخصصة لاستخدامها مباشرة داخل `validator:` الخاص بـ `TextFormField`
/// أو `AvahiTextField`.
///
/// ⚠️ هذه ليست بديلاً عن قواعد التحقق الغنية في `domain/validators/`
/// (Prompt 06) التي ستحمل منطق العمل الفعلي (مثال: تفرّد البريد
/// الإلكتروني ضمن مستأجر معيّن) — هذه الطبقة توفر فقط تحققاً فورياً
/// وخفيفاً لتحسين تجربة الإدخال قبل الإرسال.
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(
    r'^[\w\.\-\+]+@[\w\-]+\.[\w\-\.]+$',
  );

  static final RegExp _phonePattern = RegExp(r'^\+?[0-9]{7,15}$');

  /// يُعيد رسالة خطأ عند الفراغ، أو null عند صحة القيمة.
  static String? required(String? value, {String message = 'هذا الحقل مطلوب.'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'الرجاء إدخال البريد الإلكتروني.';
    if (!_emailPattern.hasMatch(value.trim())) {
      return 'صيغة البريد الإلكتروني غير صحيحة.';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'الرجاء إدخال رقم الهاتف.';
    if (!_phonePattern.hasMatch(value.trim())) {
      return 'صيغة رقم الهاتف غير صحيحة.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء إدخال كلمة المرور.';
    if (value.length < AppConstants.minPasswordLength) {
      return 'كلمة المرور يجب أن تكون ${AppConstants.minPasswordLength} أحرف على الأقل.';
    }
    return null;
  }

  /// يتحقق من تطابق كلمتي مرور (تأكيد كلمة المرور).
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'الرجاء تأكيد كلمة المرور.';
    if (value != original) return 'كلمتا المرور غير متطابقتين.';
    return null;
  }

  /// يتحقق أن الطول ضمن حدود [min]/[max] (كلاهما اختياري).
  static String? length(String? value, {int? min, int? max, String? fieldLabel}) {
    final String label = fieldLabel ?? 'القيمة';
    final int len = value?.trim().length ?? 0;
    if (min != null && len < min) return '$label يجب ألا يقل عن $min حرف.';
    if (max != null && len > max) return '$label يجب ألا يزيد عن $max حرف.';
    return null;
  }

  /// يدمج عدة دوال تحقق ويُعيد أول رسالة خطأ غير فارغة، أو null إن
  /// نجحت جميعها. مفيد لتركيب عدة قواعد على نفس الحقل بترتيب واضح.
  static String? compose(List<String? Function()> validators) {
    for (final String? Function() v in validators) {
      final String? result = v();
      if (result != null) return result;
    }
    return null;
  }
}
