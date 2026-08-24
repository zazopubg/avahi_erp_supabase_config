import 'app_exception.dart';

/// استثناءات متعلقة برفض إجراء بسبب نقص صلاحية (مرتبط بـ
/// [core/constants/permissions.dart])، أو رفض على مستوى قاعدة
/// البيانات نفسها عبر سياسات RLS (يظهر عندها كخطأ من الخادم يُغلَّف
/// هنا بعد تفسيره).
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    required super.code,
    super.cause,
    super.stackTrace,
    this.requiredPermissionName,
  });

  /// اسم الصلاحية المطلوبة (`Permission.name`) إن كان معروفاً وقت
  /// إنشاء الاستثناء، مفيد للتسجيل والتشخيص.
  final String? requiredPermissionName;

  factory PermissionException.denied({
    String? requiredPermissionName,
    Object? cause,
    StackTrace? st,
  }) =>
      PermissionException(
        message: 'لا تملك الصلاحية الكافية لتنفيذ هذا الإجراء.',
        code: 'permission.denied',
        requiredPermissionName: requiredPermissionName,
        cause: cause,
        stackTrace: st,
      );

  /// رُفض الإجراء من قِبل قاعدة البيانات (سياسة RLS) رغم اجتياز
  /// التحقق المحلي على مستوى الواجهة — يشير عادة لتضارب بيانات أو
  /// محاولة وصول خارج نطاق المستأجر (Tenant).
  factory PermissionException.deniedByPolicy({
    Object? cause,
    StackTrace? st,
  }) =>
      PermissionException(
        message: 'تم رفض هذا الإجراء من قِبل الخادم.',
        code: 'permission.denied_by_policy',
        cause: cause,
        stackTrace: st,
      );

  /// محاولة وصول إلى بيانات تخص مستأجراً (Tenant) آخر.
  factory PermissionException.crossTenantAccess({
    Object? cause,
    StackTrace? st,
  }) =>
      PermissionException(
        message: 'لا يمكن الوصول إلى بيانات خارج نطاق مؤسستك.',
        code: 'permission.cross_tenant_access',
        cause: cause,
        stackTrace: st,
      );
}
