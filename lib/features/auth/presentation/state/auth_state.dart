import '../../../../core/errors/failure.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/company.dart';

/// حالة `AuthCubit` الكاملة — Union Type مكتوب يدوياً (`sealed class` +
/// تفريغ أنماط `switch`)، **وليس عبر `freezed`**: التنفيذ الأول لهذا
/// الملف استخدم `@freezed` مع `part 'auth_state.freezed.dart';`، لكن
/// تشغيل `flutter analyze` الفعلي (قبل `dart run build_runner build`)
/// كشف أن الاعتماد على ملف مولَّد غير موجود بعد يكسر التحليل والبناء
/// مباشرة. البديل هنا لا يحتاج أي خطوة توليد كود على الإطلاق ويبقى
/// متوافقاً 100% مع نفس واجهة الاستهلاك (`when`/`maybeWhen`/`whenOrNull`،
/// وفحوصات `state is AuthLoading`/`AuthError`) المستخدمة فعلياً في
/// `presentation/screens/`، اتساقاً مع نمط `core/errors/failure.dart`
/// (`sealed class Failure`) المعتمد أصلاً في المشروع دون `freezed`.
sealed class AuthState {
  const AuthState();

  /// تفريغ أنماط شامل (Exhaustive) — كل الحالات الست إلزامية.
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(AppUser user, Company company) authenticated,
    required T Function() unauthenticated,
    required T Function(Failure failure) error,
    required T Function(List<Company> companies) needsCompanySelection,
  }) {
    final AuthState state = this;
    return switch (state) {
      AuthInitial() => initial(),
      AuthLoading() => loading(),
      AuthAuthenticated(:final user, :final company) =>
        authenticated(user, company),
      AuthUnauthenticated() => unauthenticated(),
      AuthError(:final failure) => error(failure),
      AuthNeedsCompanySelection(:final companies) =>
        needsCompanySelection(companies),
    };
  }

  /// تفريغ أنماط جزئي — كل الحالات اختيارية، مع [orElse] إلزامي كقيمة
  /// افتراضية لأي حالة غير مُمرَّرة.
  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? initial,
    T Function()? loading,
    T Function(AppUser user, Company company)? authenticated,
    T Function()? unauthenticated,
    T Function(Failure failure)? error,
    T Function(List<Company> companies)? needsCompanySelection,
  }) {
    return when<T>(
      initial: initial ?? orElse,
      loading: loading ?? orElse,
      authenticated: authenticated ?? (_, __) => orElse(),
      unauthenticated: unauthenticated ?? orElse,
      error: error ?? (_) => orElse(),
      needsCompanySelection: needsCompanySelection ?? (_) => orElse(),
    );
  }

  /// كـ [maybeWhen] لكن يعيد `null` بدل إلزام [orElse] — مناسب لكتل
  /// `listener` في `BlocConsumer` التي تتفاعل مع بعض الحالات فقط.
  T? whenOrNull<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(AppUser user, Company company)? authenticated,
    T Function()? unauthenticated,
    T Function(Failure failure)? error,
    T Function(List<Company> companies)? needsCompanySelection,
  }) {
    return maybeWhen<T?>(
      initial: initial,
      loading: loading,
      authenticated: authenticated,
      unauthenticated: unauthenticated,
      error: error,
      needsCompanySelection: needsCompanySelection,
      orElse: () => null,
    );
  }
}

/// الحالة الابتدائية قبل أي محاولة تحقق من الجلسة (قبل استدعاء
/// `checkAuthStatus()` من `SplashScreen`).
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// عملية جارية (تسجيل دخول، تحقق من الجلسة، تحميل عضويات...).
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// جلسة كاملة نشطة: مستخدم [user] ضمن شركة [company] محسومة (سواء
/// كانت عضويته الوحيدة أو المختارة عبر `selectCompany`).
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user, required this.company});

  final AppUser user;
  final Company company;
}

/// لا جلسة نشطة — الوجهة الافتراضية لـ `LoginScreen`.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// فشل صريح (بيانات دخول خاطئة، خطأ شبكة، رمز PIN غير صحيح...).
final class AuthError extends AuthState {
  const AuthError(this.failure);

  final Failure failure;
}

/// المستخدم مُصادَق بنجاح لكنه يملك أكثر من عضوية شركة نشطة —
/// [companies] القائمة الكاملة المطلوب اختيار واحدة منها عبر
/// `company_select_screen.dart`.
///
/// ⚠️ يحمل قائمة [Company] (للعرض المباشر) فقط — لا يحمل عضويات
/// [AppUser] المطابقة لها، إذ تبقى هذه الخريطة تفصيلاً داخلياً
/// لـ `AuthCubit` (`_pendingMemberships`)، وليست جزءاً من حالة العرض.
final class AuthNeedsCompanySelection extends AuthState {
  const AuthNeedsCompanySelection(this.companies);

  final List<Company> companies;
}
