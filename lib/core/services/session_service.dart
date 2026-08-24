import '../constants/storage_keys.dart';

/// واجهة خدمة إدارة الجلسة المحلية: تخزين/استرجاع/مسح بيانات الجلسة
/// (التوكنات، معرّف المستخدم، معرّف المستأجر، الدور) بشكل مستقل عن
/// مصدرها (Supabase). يُستخدم مفاتيح [StorageKeys] المعرّفة في
/// `core/constants/storage_keys.dart`.
///
/// ⚠️ التنفيذ الفعلي (اعتماداً على `flutter_secure_storage` أو تخزين
/// Drift محلي) سيُضاف ضمن `data/local/` (Prompt 08) أو `core/di/`
/// (Prompt 11). هذه الخطوة تُعرّف العقد فقط.
abstract class SessionService {
  Future<void> saveAccessToken(String token);
  Future<String?> readAccessToken();

  Future<void> saveRefreshToken(String token);
  Future<String?> readRefreshToken();

  Future<void> saveActiveTenantId(String tenantId);
  Future<String?> readActiveTenantId();

  /// يخزّن تجزئة (Hash) رمز PIN السريع محلياً — أبداً الرمز الخام
  /// نفسه. انظر `features/auth/presentation/screens/pin_screen.dart`
  /// (Prompt 13).
  Future<void> savePinHash(String hash);
  Future<String?> readPinHash();

  /// يمسح كل بيانات الجلسة المخزّنة محلياً (يُستدعى عند تسجيل الخروج
  /// أو عند اكتشاف جلسة غير صالحة).
  Future<void> clearSession();

  /// هل توجد جلسة محفوظة محلياً (بغض النظر عن صلاحيتها الفعلية لدى
  /// الخادم — التحقق من الصلاحية مسؤولية [AuthService]).
  Future<bool> hasStoredSession();
}

/// تنفيذ [SessionService] في الذاكرة فقط (`Map` داخلية) — يبقى متاحاً
/// كتنفيذ اختباري خفيف (Unit Tests) بلا أي تبعية على منصّة حقيقية.
///
/// ⚠️ **لم يعد التنفيذ المسجَّل فعلياً في التطبيق** بدءاً من
/// `features/auth/` (Prompt 13): `core/di/core_module.dart` يسجّل
/// [SecureSessionService] (`core/services/secure_session_service.dart`،
/// فوق `flutter_secure_storage`) بدلاً منه، دون أي تغيير مطلوب في بقية
/// الطبقات التي تعتمد على عقد [SessionService] نفسه فقط.
class InMemorySessionService implements SessionService {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> saveAccessToken(String token) async {
    _values[StorageKeys.authAccessToken] = token;
  }

  @override
  Future<String?> readAccessToken() async => _values[StorageKeys.authAccessToken];

  @override
  Future<void> saveRefreshToken(String token) async {
    _values[StorageKeys.authRefreshToken] = token;
  }

  @override
  Future<String?> readRefreshToken() async =>
      _values[StorageKeys.authRefreshToken];

  @override
  Future<void> saveActiveTenantId(String tenantId) async {
    _values[StorageKeys.authTenantId] = tenantId;
  }

  @override
  Future<String?> readActiveTenantId() async => _values[StorageKeys.authTenantId];

  @override
  Future<void> savePinHash(String hash) async {
    _values[StorageKeys.authPinHash] = hash;
  }

  @override
  Future<String?> readPinHash() async => _values[StorageKeys.authPinHash];

  @override
  Future<void> clearSession() async {
    _values
      ..remove(StorageKeys.authAccessToken)
      ..remove(StorageKeys.authRefreshToken)
      ..remove(StorageKeys.authUserId)
      ..remove(StorageKeys.authTenantId)
      ..remove(StorageKeys.authRole)
      ..remove(StorageKeys.authPinHash);
  }

  @override
  Future<bool> hasStoredSession() async =>
      _values.containsKey(StorageKeys.authAccessToken);
}
