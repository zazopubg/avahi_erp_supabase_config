import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../navigation/route_names.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../state/auth_cubit.dart';
import '../state/auth_state.dart';
import '../widgets/login_form.dart';

/// شاشة تسجيل الدخول الفعلية — تستهلك [AuthCubit] عبر `BlocConsumer`:
/// `listener` يتولى التنقّل (نجاح/تعدد عضويات) وعرض الأخطاء
/// (`SnackBar`)، بينما `builder` يعرض [LoginForm] بحالة تحميل/خطأ
/// مطابقة لآخر [AuthState] صادرة.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (BuildContext context, AuthState state) {
            state.whenOrNull(
              authenticated: (_, __) => context.goNamed(RouteNames.home),
              needsCompanySelection: (_) =>
                  context.goNamed(RouteNames.companySelect),
              error: (Failure failure) => context.showSnackBar(failure.message),
            );
          },
          builder: (BuildContext context, AuthState state) {
            final bool isLoading = state is AuthLoading;
            final String? errorText =
                state is AuthError ? state.failure.message : null;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AvahiSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Icon(
                        Icons.construction_rounded,
                        size: 56,
                        color: context.colors.primary,
                      ),
                      const SizedBox(height: AvahiSpacing.md),
                      Text(
                        'أفاهي',
                        textAlign: TextAlign.center,
                        style: context.textTheme.headlineMedium,
                      ),
                      Text(
                        'تسجيل الدخول لمتابعة العمل',
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AvahiSpacing.xl),
                      LoginForm(
                        isLoading: isLoading,
                        errorText: errorText,
                        onSubmit: (String email, String password) {
                          context.read<AuthCubit>().login(
                                email: email,
                                password: password,
                              );
                        },
                      ),
                      const SizedBox(height: AvahiSpacing.md),
                      Center(
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.goNamed(RouteNames.forgotPassword),
                          child: const Text('نسيت كلمة المرور؟'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
