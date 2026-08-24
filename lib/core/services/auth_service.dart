import '../errors/failure.dart';

/// تمثيل مبسّط لجلسة مصادقة، مستقل عن أي مزوّد فعلي (Supabase Auth
/// يُربط لاحقاً في `data/cloud/supabase/auth/`، Prompt 07). يحمل فقط
/// الحد الأدنى من المعلومات التي تحتاجها طبقة `core`/`ui` قبل وجود
/// كيانات `domain/entities/` الكاملة (Prompt 05).
class AuthSessionInfo {
  const AuthSessionInfo({
    required this.userId,
    required this.tenantId,
    required this.roleName,
    this.email,
  });

  final String userId;
  final String tenantId;
  final String roleName;
  final String? email;
}

/// واجهة خدمة المصادقة العامة.
///
/// ⚠️ هذه الخطوة (Prompt 02) تُعرّف فقط العقد (Contract) دون أي تنفيذ
/// فعلي متصل بـ Supabase. سيُنفَّذ هذا العقد ضمن `data/cloud/supabase/
/// auth/` (Prompt 07) ثم يُسجَّل عبر `core/di/` (Prompt 11)، ليُستهلك
/// بدوره من `domain/repositories/` و`features/auth/` لاحقاً.
abstract class AuthService {
  /// الجلسة الحالية إن وُجدت، أو null إن لم يكن هناك مستخدم مسجّل.
  AuthSessionInfo? get currentSession;

  /// تدفّق يُصدر الجلسة الحالية عند كل تغيير (دخول/خروج/انتهاء صلاحية).
  Stream<AuthSessionInfo?> get sessionChanges;

  Future<ResultOf<AuthSessionInfo>> signInWithPassword({
    required String email,
    required String password,
  });

  Future<ResultOf<void>> signOut();

  Future<ResultOf<void>> sendPasswordResetEmail(String email);
}
