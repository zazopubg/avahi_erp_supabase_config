import 'package:avahi/features/auth/presentation/screens/login_screen.dart';
import 'package:avahi/features/auth/presentation/state/auth_cubit.dart';
import 'package:avahi/features/auth/presentation/state/auth_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

/// 🆕 (Prompt 29) اختبارات Golden لتكبير النص — تتحقق من أمرين معاً
/// لكل نسبة تكبير مطلوبة (100%/130%/140%، حدود [TextScaleGuard]
/// الآمنة 0.85–1.4):
/// 1) **لا Overflow إطلاقاً**: [tester.takeException] يجب أن يعيد
///    `null` بعد `pumpAndSettle` — أي `RenderFlex overflowed by...`
///    فعلي كان سيظهر هنا كاستثناء ملتقط أثناء البناء.
/// 2) **تطابق بصري (Golden File)**: عبر [matchesGoldenFile] القياسي
///    من `flutter_test` (بلا اعتماد `golden_toolkit` خارجي). عند أول
///    تشغيل لهذا الملف لا توجد صور مرجعية بعد — نفّذ
///    `flutter test --update-goldens test/golden/text_scaling/` مرة
///    واحدة لتوليدها، ثم `flutter test` العادي يقارن بها لاحقاً.
class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockAuthCubit cubit;

  setUp(() {
    cubit = MockAuthCubit();
    const AuthState state = AuthUnauthenticated();
    when(() => cubit.state).thenReturn(state);
    whenListen(cubit, const Stream<AuthState>.empty(), initialState: state);
  });

  Future<void> pumpAtScale(WidgetTester tester, double textScale) async {
    await tester.pumpAvahiApp(
      BlocProvider<AuthCubit>.value(
        value: cubit,
        child: const LoginScreen(),
      ),
      textScale: textScale,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('شاشة تسجيل الدخول بلا Overflow عند تكبير نص 100% (الافتراضي)',
      (WidgetTester tester) async {
    await pumpAtScale(tester, 1.0);

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_screen_text_scale_100.png'),
    );
  });

  testWidgets('شاشة تسجيل الدخول بلا Overflow عند تكبير نص 130%',
      (WidgetTester tester) async {
    await pumpAtScale(tester, 1.3);

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_screen_text_scale_130.png'),
    );
  });

  testWidgets(
      'شاشة تسجيل الدخول بلا Overflow عند تكبير نص 140% (الحد الأقصى '
      'المسموح في TextScaleGuard)', (WidgetTester tester) async {
    await pumpAtScale(tester, 1.4);

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_screen_text_scale_140.png'),
    );
  });
}
