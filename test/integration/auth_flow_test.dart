import 'package:avahi/core/errors/failure.dart';
import 'package:avahi/core/services/session_service.dart';
import 'package:avahi/domain/entities/app_user.dart';
import 'package:avahi/domain/entities/company.dart';
import 'package:avahi/domain/repositories/i_auth_repository.dart';
import 'package:avahi/domain/repositories/i_company_repository.dart';
import 'package:avahi/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:avahi/domain/usecases/auth/get_user_memberships_usecase.dart';
import 'package:avahi/domain/usecases/auth/login_usecase.dart';
import 'package:avahi/domain/usecases/auth/logout_usecase.dart';
import 'package:avahi/domain/usecases/auth/send_password_reset_email_usecase.dart';
import 'package:avahi/domain/usecases/company/get_company_by_id_usecase.dart';
import 'package:avahi/features/auth/presentation/state/auth_cubit.dart';
import 'package:avahi/features/auth/presentation/state/auth_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fixtures.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

class MockCompanyRepository extends Mock implements ICompanyRepository {}

Company _company({required String id, String name = 'Bewar'}) {
  final DateTime now = Fixtures.baseTime;
  return Company(
    id: id,
    name: name,
    slug: id,
    timezone: 'Asia/Baghdad',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockAuthRepository authRepository;
  late MockCompanyRepository companyRepository;
  late InMemorySessionService sessionService;
  late AuthCubit cubit;

  AuthCubit buildCubit() {
    return AuthCubit(
      loginUsecase: LoginUsecase(authRepository),
      logoutUsecase: LogoutUsecase(authRepository),
      getCurrentUserUsecase: GetCurrentUserUsecase(authRepository),
      getUserMembershipsUsecase: GetUserMembershipsUsecase(authRepository),
      getCompanyByIdUsecase: GetCompanyByIdUsecase(companyRepository),
      sendPasswordResetEmailUsecase: SendPasswordResetEmailUsecase(authRepository),
      sessionService: sessionService,
    );
  }

  setUp(() {
    authRepository = MockAuthRepository();
    companyRepository = MockCompanyRepository();
    sessionService = InMemorySessionService();
    cubit = buildCubit();
  });

  tearDown(() => cubit.close());

  group('تدفق تسجيل الدخول الكامل — عضوية واحدة', () {
    blocTest<AuthCubit, AuthState>(
      'تسجيل دخول ناجح بعضوية واحدة فقط ← Loading ثم Authenticated مباشرة، '
      'مع حفظ معرّف المستأجر النشط فعلياً في SessionService',
      build: buildCubit,
      setUp: () {
        final AppUser membership = Fixtures.appUser();
        when(() => authRepository.login(email: 'worker@bewar.iq', password: 'secret123'))
            .thenAnswer((_) async => Right<Failure, AppUser>(membership));
        when(() => authRepository.getUserMemberships('user-1')).thenAnswer(
          (_) async => Right<Failure, List<AppUser>>(<AppUser>[membership]),
        );
        when(() => companyRepository.getCompanyById('company-1')).thenAnswer(
          (_) async => Right<Failure, Company>(_company(id: 'company-1')),
        );
      },
      act: (AuthCubit c) => c.login(email: 'worker@bewar.iq', password: 'secret123'),
      expect: () => <Matcher>[
        isA<AuthLoading>(),
        isA<AuthAuthenticated>()
            .having((AuthAuthenticated s) => s.company.id, 'company.id', 'company-1'),
      ],
      verify: (_) async {
        expect(await sessionService.readActiveTenantId(), 'company-1');
      },
    );

    blocTest<AuthCubit, AuthState>(
      'بيانات دخول خاطئة ← Loading ثم Error، دون أي محاولة جلب عضويات أو '
      'حفظ جلسة',
      build: buildCubit,
      setUp: () {
        when(() => authRepository.login(email: 'worker@bewar.iq', password: 'wrong'))
            .thenAnswer(
          (_) async => const Left<Failure, AppUser>(
            AuthFailure(message: 'بيانات الدخول غير صحيحة.', code: 'auth.invalid_credentials'),
          ),
        );
      },
      act: (AuthCubit c) => c.login(email: 'worker@bewar.iq', password: 'wrong'),
      expect: () => <Matcher>[isA<AuthLoading>(), isA<AuthError>()],
      verify: (_) async {
        verifyNever(() => authRepository.getUserMemberships(any()));
        expect(await sessionService.readActiveTenantId(), isNull);
      },
    );
  });

  group('تدفق تسجيل الدخول الكامل — تعدد العضويات واختيار الشركة', () {
    blocTest<AuthCubit, AuthState>(
      'تسجيل دخول بعضويتين ← NeedsCompanySelection، ثم اختيار إحداهما ← '
      'Authenticated بالعضوية الصحيحة المطابقة',
      build: buildCubit,
      setUp: () {
        final AppUser membershipA = Fixtures.appUser(
          id: 'member-a',
          companyId: 'company-a',
        );
        final AppUser membershipB = Fixtures.appUser(
          id: 'member-b',
          companyId: 'company-b',
        );
        when(() => authRepository.login(email: 'pm@bewar.iq', password: 'secret123'))
            .thenAnswer((_) async => Right<Failure, AppUser>(membershipA));
        when(() => authRepository.getUserMemberships('user-1')).thenAnswer(
          (_) async => Right<Failure, List<AppUser>>(<AppUser>[membershipA, membershipB]),
        );
        when(() => companyRepository.getCompanyById('company-a')).thenAnswer(
          (_) async => Right<Failure, Company>(_company(id: 'company-a', name: 'Company A')),
        );
        when(() => companyRepository.getCompanyById('company-b')).thenAnswer(
          (_) async => Right<Failure, Company>(_company(id: 'company-b', name: 'Company B')),
        );
      },
      act: (AuthCubit c) async {
        await c.login(email: 'pm@bewar.iq', password: 'secret123');
        final AuthState afterLogin = c.state;
        expect(afterLogin, isA<AuthNeedsCompanySelection>());
        final Company chosen = (afterLogin as AuthNeedsCompanySelection)
            .companies
            .firstWhere((Company company) => company.id == 'company-b');
        await c.selectCompany(chosen);
      },
      expect: () => <Matcher>[
        isA<AuthLoading>(),
        isA<AuthNeedsCompanySelection>().having(
          (AuthNeedsCompanySelection s) => s.companies.map((Company c) => c.id).toList(),
          'companies',
          <String>['company-a', 'company-b'],
        ),
        isA<AuthAuthenticated>().having(
          (AuthAuthenticated s) => s.user.companyId,
          'user.companyId',
          'company-b',
        ),
      ],
      verify: (_) async {
        expect(await sessionService.readActiveTenantId(), 'company-b');
      },
    );
  });

  group('تدفق تسجيل الخروج', () {
    blocTest<AuthCubit, AuthState>(
      'تسجيل الخروج بعد جلسة نشطة ← Unauthenticated، ومسح الجلسة المحلية '
      'فعلياً (SessionService)',
      build: buildCubit,
      setUp: () async {
        when(() => authRepository.logout())
            .thenAnswer((_) async => const Right<Failure, void>(null));
        await sessionService.saveActiveTenantId('company-1');
        await sessionService.saveAccessToken('token-abc');
      },
      act: (AuthCubit c) => c.logout(),
      expect: () => <Matcher>[isA<AuthUnauthenticated>()],
      verify: (_) async {
        expect(await sessionService.hasStoredSession(), isFalse);
        expect(await sessionService.readActiveTenantId(), isNull);
      },
    );
  });
}
