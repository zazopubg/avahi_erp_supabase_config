import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/company.dart';
import '../../../../domain/enums/user_role.dart';
import '../../../../ui/widgets/common/error_view.dart';
import '../../../../ui/widgets/common/loading_indicator.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../state/home_cubit.dart';
import '../state/home_state.dart';
import 'manager_home.dart';
import 'supervisor_home.dart';
import 'worker_home.dart';

/// نقطة الدخول الفعلية لميزة `features/home/` (Prompt 14) — تستبدل
/// `HomePlaceholderScreen` المؤقتة (`navigation/placeholder_screens.dart`،
/// Prompt 12/13) كشاشة `RoutePaths.home` الفعلية ضمن `navigation/app_router.dart`.
///
/// تقرأ [AppUser]/[Company] الحاليين مباشرة من `AuthCubit.state`
/// (وليس عبر `UseCase` منفصل: `AuthCubit` هو مصدر الحقيقة الوحيد
/// لجلسة المستخدم النشطة أصلاً — انظر `features/auth/`)، ثم تُنشئ
/// [HomeCubit] خاصاً بها (`sl<HomeCubit>()`) وتستدعي `loadHome(user)`
/// فور توفره، وأخيراً تُفوّض عرض المحتوى الفعلي حسب [UserRole] إلى
/// واحدة من ثلاث شاشات فرعية: [WorkerHome] / [SupervisorHome] /
/// [ManagerHome].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return authState.maybeWhen<Widget>(
          authenticated: (AppUser user, Company company) {
            return BlocProvider<HomeCubit>(
              create: (_) => sl<HomeCubit>()..loadHome(user),
              child: _HomeBody(user: user, company: company),
            );
          },
          // نظرياً لا تصل هذه الشاشة إطلاقاً بحالة غير `authenticated`
          // (`AuthGuard` يحجب مسار `/home` كاملاً بدون جلسة نشطة، انظر
          // `navigation/guards/auth_guard.dart`)، لكن تبقى حالة تحميل
          // بسيطة أأمن من شاشة فارغة أثناء أي لحظة انتقالية عابرة
          // (مثال: بين `AuthLoading` و`AuthAuthenticated` مباشرة بعد
          // `checkAuthStatus()`).
          orElse: () => const Scaffold(
            body: LoadingIndicator(label: 'جارٍ تحميل الجلسة...'),
          ),
        );
      },
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.user, required this.company});

  final AppUser user;
  final Company company;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (BuildContext context, HomeState state) {
        return state.when<Widget>(
          initial: () => const Scaffold(body: LoadingIndicator()),
          loading: () => const Scaffold(
            body: LoadingIndicator(label: 'جارٍ تحميل ملخص اليوم...'),
          ),
          error: (failure) => Scaffold(
            appBar: AppBar(title: Text(company.name)),
            body: ErrorView(
              title: 'تعذّر تحميل الشاشة الرئيسية',
              message: failure.message,
              onRetry: () => context.read<HomeCubit>().loadHome(user),
            ),
          ),
          loaded: (HomeSummary summary) {
            return switch (user.role) {
              UserRole.worker => WorkerHome(
                  user: user,
                  company: company,
                  summary: summary,
                ),
              UserRole.foreman ||
              UserRole.engineer =>
                SupervisorHome(
                  user: user,
                  company: company,
                  summary: summary,
                ),
              UserRole.projectManager ||
              UserRole.admin ||
              UserRole.platformOwner =>
                ManagerHome(
                  user: user,
                  company: company,
                  summary: summary,
                ),
            };
          },
        );
      },
    );
  }
}
