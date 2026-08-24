import 'package:avahi/features/auth/presentation/screens/login_screen.dart';
import 'package:avahi/features/auth/presentation/state/auth_cubit.dart';
import 'package:avahi/features/auth/presentation/state/auth_state.dart';
import 'package:avahi/ui/rtl/directionality_provider.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  group('AvahiDirectionalityProvider — تحديد الاتجاه حسب رمز اللغة', () {
    test('العربية (ar) تُعتبر RTL', () {
      expect(AvahiDirectionalityProvider.isRtl(const Locale('ar')), isTrue);
      expect(
        AvahiDirectionalityProvider.directionOf(const Locale('ar')),
        TextDirection.rtl,
      );
    });

    test('العبرية (he) والفارسية (fa) والأردية (ur) تُعتبر RTL أيضاً', () {
      expect(AvahiDirectionalityProvider.isRtl(const Locale('he')), isTrue);
      expect(AvahiDirectionalityProvider.isRtl(const Locale('fa')), isTrue);
      expect(AvahiDirectionalityProvider.isRtl(const Locale('ur')), isTrue);
    });

    test('الإنجليزية (en) تُعتبر LTR', () {
      expect(AvahiDirectionalityProvider.isRtl(const Locale('en')), isFalse);
      expect(
        AvahiDirectionalityProvider.directionOf(const Locale('en')),
        TextDirection.ltr,
      );
    });
  });

  group('RTL Layout — التوجيه الفعلي المُطبَّق على الشجرة', () {
    late MockAuthCubit cubit;

    setUp(() {
      cubit = MockAuthCubit();
      const AuthState state = AuthUnauthenticated();
      when(() => cubit.state).thenReturn(state);
      whenListen(cubit, const Stream<AuthState>.empty(), initialState: state);
    });

    testWidgets('اللغة العربية الافتراضية تُطبِّق Directionality.rtl فعلياً '
        'على شجرة الشاشة', (WidgetTester tester) async {
      await tester.pumpAvahiApp(
        BlocProvider<AuthCubit>.value(value: cubit, child: const LoginScreen()),
      );
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(LoginScreen));
      expect(Directionality.of(context), TextDirection.rtl);
    });

    testWidgets('التبديل إلى اللغة الإنجليزية يُطبِّق Directionality.ltr '
        'بدلاً منها', (WidgetTester tester) async {
      await tester.pumpAvahiApp(
        BlocProvider<AuthCubit>.value(value: cubit, child: const LoginScreen()),
        locale: const Locale('en'),
      );
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(LoginScreen));
      expect(Directionality.of(context), TextDirection.ltr);
    });

    testWidgets(
        'أيقونة حقل البريد الإلكتروني (prefixIcon) تقع على يمين الحقل '
        'في RTL — أي بإحداثي X أكبر من إحداثي X لحقل النص نفسه',
        (WidgetTester tester) async {
      await tester.pumpAvahiApp(
        BlocProvider<AuthCubit>.value(value: cubit, child: const LoginScreen()),
      );
      await tester.pumpAndSettle();

      final Finder emailFieldFinder = find.byType(TextFormField).first;
      final Finder mailIconFinder = find.byIcon(Icons.mail_outline);

      final double fieldCenterX = tester.getRect(emailFieldFinder).center.dx;
      final double iconCenterX = tester.getCenter(mailIconFinder).dx;

      // في RTL: البادئة (prefixIcon) تُرسَم بصرياً عند الحافة اليمنى
      // (وهي حافة "البداية" منطقياً) — أي عند إحداثي X أكبر من منتصف
      // صندوق الحقل بأكمله.
      expect(iconCenterX, greaterThan(fieldCenterX));
    });

    testWidgets('نفس الأيقونة تنتقل لليسار (إحداثي X أصغر تقريباً من '
        'منتصف الحقل) عند التبديل إلى LTR', (WidgetTester tester) async {
      await tester.pumpAvahiApp(
        BlocProvider<AuthCubit>.value(value: cubit, child: const LoginScreen()),
        locale: const Locale('en'),
      );
      await tester.pumpAndSettle();

      final Finder emailFieldFinder = find.byType(TextFormField).first;
      final Finder mailIconFinder = find.byIcon(Icons.mail_outline);

      final double fieldCenterX = tester.getRect(emailFieldFinder).center.dx;
      final double iconCenterX = tester.getCenter(mailIconFinder).dx;

      expect(iconCenterX, lessThan(fieldCenterX));
    });
  });

  group('RTL — لقطة Golden مرجعية لشاشة تسجيل الدخول', () {
    late MockAuthCubit cubit;

    setUp(() {
      cubit = MockAuthCubit();
      const AuthState state = AuthUnauthenticated();
      when(() => cubit.state).thenReturn(state);
      whenListen(cubit, const Stream<AuthState>.empty(), initialState: state);
    });

    testWidgets(
        'لقطة Golden لشاشة تسجيل الدخول بالعربية (RTL) — نفّذ '
        '`flutter test --update-goldens` أول مرة لتوليد الصورة المرجعية',
        (WidgetTester tester) async {
      await tester.pumpAvahiApp(
        BlocProvider<AuthCubit>.value(value: cubit, child: const LoginScreen()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(LoginScreen),
        matchesGoldenFile('goldens/login_screen_rtl_ar.png'),
      );
    });
  });
}
