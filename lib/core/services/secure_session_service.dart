import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';
import 'session_service.dart';

/// تنفيذ [SessionService] الفعلي فوق `flutter_secure_storage` — يُبقي
/// الجلسة (توكنات، معرّف المستأجر النشط، تجزئة PIN) محفوظة عبر إعادة
/// تحميل الصفحة (Web Refresh) وإغلاق/فتح التطبيق، بخلاف
/// [InMemorySessionService] المؤقت الذي سبقه (Prompt 02/11).
///
/// مسجَّل عبر `core/di/core_module.dart` بدءاً من `features/auth/`
/// (Prompt 13) بديلاً وحيداً عن [InMemorySessionService] لعقد
/// [SessionService] نفسه — لا تغيير مطلوب في أي طبقة أعلى تستهلك
/// `sl<SessionService>()`.
class SecureSessionService implements SessionService {
  SecureSessionService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: StorageKeys.authAccessToken, value: token);

  @override
  Future<String?> readAccessToken() =>
      _storage.read(key: StorageKeys.authAccessToken);

  @override
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: StorageKeys.authRefreshToken, value: token);

  @override
  Future<String?> readRefreshToken() =>
      _storage.read(key: StorageKeys.authRefreshToken);

  @override
  Future<void> saveActiveTenantId(String tenantId) =>
      _storage.write(key: StorageKeys.authTenantId, value: tenantId);

  @override
  Future<String?> readActiveTenantId() =>
      _storage.read(key: StorageKeys.authTenantId);

  @override
  Future<void> savePinHash(String hash) =>
      _storage.write(key: StorageKeys.authPinHash, value: hash);

  @override
  Future<String?> readPinHash() => _storage.read(key: StorageKeys.authPinHash);

  @override
  Future<void> clearSession() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: StorageKeys.authAccessToken),
      _storage.delete(key: StorageKeys.authRefreshToken),
      _storage.delete(key: StorageKeys.authUserId),
      _storage.delete(key: StorageKeys.authTenantId),
      _storage.delete(key: StorageKeys.authRole),
      _storage.delete(key: StorageKeys.authPinHash),
    ]);
  }

  @override
  Future<bool> hasStoredSession() async {
    final String? token = await readAccessToken();
    return token != null && token.isNotEmpty;
  }
}
