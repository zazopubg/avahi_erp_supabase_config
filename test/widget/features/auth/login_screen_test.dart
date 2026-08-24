import 'package:avahi/core/errors/failure.dart';
import 'package:avahi/features/auth/presentation/screens/login_screen.dart';
import 'package:avahi/features/auth/presentation/state/auth_cubit.dart';
import 'package:avahi/features/auth/presentation/state/auth_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockAuthCubit cubit;

  Future<void> pumpScreen(
    WidgetTester tester, {
    required AuthState state,
  }) async {
    when(() => cubit.state).thenReturn(state);
    whenListen(cubit, const Stream<AuthState>.empty(), initialState: state);

    await tester.pumpAvahiApp(
      BlocProvider<AuthCubit>.value(
        value: cubit,
        child: const LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    cubit = MockAuthCubit();
    when(() => cubit.login(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async {});
  });

  group('LoginScreen — عرض حسب الحالة (Static rendering)', () {
    testWidgets('يعرض حقلي البريد وكلمة المرور وزر تسجيل الدخول في '
        'الحالة غير المصادَقة', (WidgetTester tester) async {
      await pumpScreen(tester, state: const AuthUnauthenticated());

      expect(find.text('البريد الإلكتروني'), findsOneWidget);
      expect(find.text('كلمة المرور'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'تسجيل الدخول'), findsOneWidget);
    });

    testWidgets('يعرض مؤشر تحميل بدل نص الزر أثناء AuthLoading',
        (WidgetTester tester) async {
      await pumpScreen(tester, state: const AuthLoading());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('تسجيل الدخول'), findsNothing);
    });

    testWidgets('يعرض رسالة الفشل القادمة من AuthError أسفل الحقول',
        (WidgetTester tester) async {
      const Failure failure = ValidationFailure(
        message: 'بيانات الدخول غير صحيحة.',
        code: 'auth.invalid_credentials',
      );

      await pumpScreen(tester, state: const AuthError(failure));

      expect(find.text('بيانات الدخول غير صحيحة.'), findsOneWidget);
    });

    testWidgets('تُعطَّل الحقول أثناء AuthLoading', (WidgetTester tester) async {
      await pumpScreen(tester, state: const AuthLoading());

      final TextFormField emailField =
          tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(emailField.enabled, isFalse);
    });
  });

  group('LoginScreen — تقديم النموذج', () {
    testWidgets(
        'يستدعي AuthCubit.login بالبريد وكلمة المرور بعد اجتياز التحقق '
        'المحلي', (WidgetTester tester) async {
      await pumpScreen(tester, state: const AuthUnauthenticated());

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'worker@bewar.iq',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'p@ssword123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'تسجيل الدخول'));
      await tester.pumpAndSettle();

      verify(
        () => cubit.login(email: 'worker@bewar.iq', password: 'p@ssword123'),
      ).called(1);
    });

    testWidgets('لا يستدعي AuthCubit.login عند ترك الحقول فارغة (فشل '
        'التحقق المحلي)', (WidgetTester tester) async {
      await pumpScreen(tester, state: const AuthUnauthenticated());

      await tester.tap(find.widgetWithText(ElevatedButton, 'تسجيل الدخول'));
      await tester.pumpAndSettle();

      expect(find.text('الرجاء إدخال البريد الإلكتروني.'), findsOneWidget);
      verifyNever(
        () => cubit.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    testWidgets('لا يستدعي AuthCubit.login عند بريد بصيغة غير صحيحة',
        (WidgetTester tester) async {
      await pumpScreen(tester, state: const AuthUnauthenticated());

      await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
      await tester.enterText(find.byType(TextFormField).at(1), 'p@ssword123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'تسجيل الدخول'));
      await tester.pumpAndSettle();

      expect(find.text('صيغة البريد الإلكتروني غير صحيحة.'), findsOneWidget);
      verifyNever(
        () => cubit.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });
  });
}
