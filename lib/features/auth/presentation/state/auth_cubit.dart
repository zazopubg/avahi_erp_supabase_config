import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/pin_hasher.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/company.dart';
import '../../../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../../../domain/usecases/auth/get_user_memberships_usecase.dart';
import '../../../../domain/usecases/auth/login_usecase.dart';
import '../../../../domain/usecases/auth/logout_usecase.dart';
import '../../../../domain/usecases/auth/send_password_reset_email_usecase.dart';
import '../../../../domain/usecases/company/get_company_by_id_usecase.dart';
import 'auth_state.dart';

/// `Cubit` ميزة المصادقة الكاملة — الجهة الوحيدة في `features/auth/`
/// التي تستدعي `UseCases` طبقة `domain/` مباشرة؛ كل الشاشات
/// (`presentation/screens/`) تستهلك [AuthState] عبر `BlocConsumer`/
/// `BlocBuilder` فقط دون أي منطق عمل داخلها.
///
/// ⚠️ تدفّق تعدد العضويات: [_pendingMemberships] تفصيل داخلي **خاص
/// بهذا الـ Cubit فقط** (وليس جزءاً من [AuthState]) — يُملأ عند حسم
/// [AuthNeedsCompanySelection] ويُستهلك مرة واحدة عبر
/// [selectCompany] لمطابقة [Company] المُختارة بعضويتها [AppUser]
/// المقابلة (نفس [Company.id] == [AppUser.companyId]).
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required LoginUsecase loginUsecase,
    required LogoutUsecase logoutUsecase,
    required GetCurrentUserUsecase getCurrentUserUsecase,
    required GetUserMembershipsUsecase getUserMembershipsUsecase,
    required GetCompanyByIdUsecase getCompanyByIdUsecase,
    required SendPasswordResetEmailUsecase sendPasswordResetEmailUsecase,
    required SessionService sessionService,
  })  : _loginUsecase = loginUsecase,
        _logoutUsecase = logoutUsecase,
        _getCurrentUserUsecase = getCurrentUserUsecase,
        _getUserMembershipsUsecase = getUserMembershipsUsecase,
        _getCompanyByIdUsecase = getCompanyByIdUsecase,
        _sendPasswordResetEmailUsecase = sendPasswordResetEmailUsecase,
        _sessionService = sessionService,
        super(const AuthInitial());

  final LoginUsecase _loginUsecase;
  final LogoutUsecase _logoutUsecase;
  final GetCurrentUserUsecase _getCurrentUserUsecase;
  final GetUserMembershipsUsecase _getUserMembershipsUsecase;
  final GetCompanyByIdUsecase _getCompanyByIdUsecase;
  final SendPasswordResetEmailUsecase _sendPasswordResetEmailUsecase;
  final SessionService _sessionService;

  List<AppUser> _pendingMemberships = const <AppUser>[];

  /// تُستدعى مرة واحدة من `SplashScreen` عند فتح التطبيق — تتحقق من
  /// وجود جلسة نشطة فعلياً (وليس فقط توكن محفوظ محلياً) ثم توجّه
  /// تلقائياً عبر [AuthState] الناتجة (`AuthGuard` يتكفّل بالتنقل
  /// الفعلي استناداً لهذه الحالة، وليس هذا الـ Cubit).
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading());

    final ResultOf<AppUser?> result = await _getCurrentUserUsecase();
    await result.fold(
      (Failure failure) async => emit(AuthError(failure)),
      (AppUser? user) async {
        if (user == null) {
          emit(const AuthUnauthenticated());
          return;
        }
        await _resolveMembership(user);
      },
    );
  }

  /// تسجيل الدخول عبر البريد وكلمة المرور (`login_screen.dart`).
  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading());

    final ResultOf<AppUser> result = await _loginUsecase(
      email: email,
      password: password,
    );
    await result.fold(
      (Failure failure) async => emit(AuthError(failure)),
      (AppUser user) async => _resolveMembership(user),
    );
  }

  /// يُستدعى من `company_select_screen.dart` بعد اختيار المستخدم شركة
  /// من [AuthNeedsCompanySelection]. يفترض أن [company] عنصر من
  /// نفس القائمة التي عُرضت فعلياً (لا يُعيد جلبها من الشبكة).
  Future<void> selectCompany(Company company) async {
    final AppUser membership = _pendingMemberships.firstWhere(
      (AppUser m) => m.companyId == company.id,
      orElse: () => throw StateError(
        'لا توجد عضوية مطابقة للشركة المختارة ضمن العضويات المُحمَّلة.',
      ),
    );

    await _sessionService.saveActiveTenantId(company.id);
    emit(AuthAuthenticated(user: membership, company: company));
  }

  /// تسجيل الخروج — يُنهي الجلسة السحابية والمحلية ويمسح رمز PIN
  /// المحفوظ (جهاز قد يُستخدمه مستخدم آخر لاحقاً).
  Future<void> logout() async {
    await _logoutUsecase();
    await _sessionService.clearSession();
    _pendingMemberships = const <AppUser>[];
    emit(const AuthUnauthenticated());
  }

  /// يرسل رسالة إعادة تعيين كلمة مرور — لا يُغيّر [AuthState] عمداً
  /// (`forgot_password_screen.dart` يدير حالة نجاح/فشل محلية خاصة بها
  /// بدل التأثير على حالة المصادقة العامة للتطبيق).
  Future<ResultOf<void>> sendPasswordResetEmail(String email) {
    return _sendPasswordResetEmailUsecase(email);
  }

  /// صحيح إن كان هناك رمز PIN محفوظ مسبقاً على هذا الجهاز
  /// (`pin_screen.dart` يستخدمها لتحديد وضع العرض: إنشاء أم تحقق).
  Future<bool> hasPinConfigured() async {
    final String? hash = await _sessionService.readPinHash();
    return hash != null && hash.isNotEmpty;
  }

  /// ينشئ/يستبدل رمز PIN المحلي (تجزئته فقط تُخزَّن — انظر [PinHasher]).
  Future<void> createPin(String pin) async {
    await _sessionService.savePinHash(PinHasher.hash(pin));
  }

  /// يتحقق من رمز PIN المُدخَل مقابل التجزئة المحفوظة؛ عند التطابق لا
  /// يُغيّر [AuthState] بنفسه — الشاشة المستدعية (`pin_screen.dart`) هي
  /// من تتولى التنقل بعد نجاح التحقق (الجلسة الفعلية تبقى محفوظة
  /// أصلاً عبر `SessionService`/Supabase طوال الوقت، والـ PIN بوابة
  /// دخول سريعة محلية فقط وليس إعادة مصادقة كاملة).
  Future<bool> verifyPin(String pin) async {
    final String? storedHash = await _sessionService.readPinHash();
    if (storedHash == null || storedHash.isEmpty) return false;
    return PinHasher.matches(pin, storedHash);
  }

  /// يحسم — بعد نجاح مصادقة [user] (دخول جديد أو جلسة محفوظة) — ما إذا
  /// كانت شركته الواحدة معروفة مباشرة أم يلزم عرض شاشة اختيار شركة عند
  /// تعدد العضويات النشطة.
  Future<void> _resolveMembership(AppUser user) async {
    final ResultOf<List<AppUser>> membershipsResult =
        await _getUserMembershipsUsecase(user.userId);

    await membershipsResult.fold(
      (Failure failure) async => emit(AuthError(failure)),
      (List<AppUser> memberships) async {
        if (memberships.length <= 1) {
          await _emitAuthenticated(user);
          return;
        }

        _pendingMemberships = memberships;
        final List<Company> companies = <Company>[];
        for (final AppUser membership in memberships) {
          final ResultOf<Company> companyResult =
              await _getCompanyByIdUsecase(membership.companyId);
          companyResult.fold(
            (Failure _) {},
            (Company company) => companies.add(company),
          );
        }
        emit(AuthNeedsCompanySelection(companies));
      },
    );
  }

  /// يجلب بيانات شركة [user] الوحيدة ويصدر [AuthAuthenticated].
  Future<void> _emitAuthenticated(AppUser user) async {
    final ResultOf<Company> companyResult =
        await _getCompanyByIdUsecase(user.companyId);
    await companyResult.fold(
      (Failure failure) async => emit(AuthError(failure)),
      (Company company) async {
        await _sessionService.saveActiveTenantId(company.id);
        emit(AuthAuthenticated(user: user, company: company));
      },
    );
  }
}
