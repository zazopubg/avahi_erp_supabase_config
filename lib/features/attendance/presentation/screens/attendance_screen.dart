import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/permissions.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../ui/widgets/common/error_view.dart';
import '../../../../ui/widgets/common/loading_indicator.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../state/attendance_cubit.dart';
import '../state/attendance_state.dart';
import 'desktop/attendance_desktop_home.dart';
import 'mobile/attendance_mobile_home.dart';

/// نقطة الدخول الوحيدة لكامل ميزة الحضور — الشاشة المربوطة فعلياً
/// بـ `RouteNames.attendance` ضمن `app_router.dart` (المسار الوحيد
/// المحمي بـ `RoleGuard` عبر `AppNavDestinations.attendance`، بصلاحية
/// [Permission.attendanceCheckInSelf] لكل الأدوار — انظر توثيق قرار
/// التنقّل الكامل في `attendance_cubit.dart`).
///
/// توفّر [AttendanceCubit] محلياً (بنفس نمط `HomeScreen`)، وتفرّع
/// العرض حسب [ShellMode] فقط: [AttendanceMobileHome] للعرض الضيق
/// (< 600) و[AttendanceDesktopHome] لما هو أوسع (لوحي/سطح مكتب) —
/// التمييز بين "عامل ميداني" و"مشرف يراقب فريقه" يتم داخل
/// [AttendanceDesktopHome] نفسها عبر فحص [Permission.attendanceApproveTeam].
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return authState.maybeWhen<Widget>(
          orElse: () => const Scaffold(body: LoadingIndicator()),
          authenticated: (AppUser user, _) {
            return BlocProvider<AttendanceCubit>(
              create: (_) => sl<AttendanceCubit>()..loadInitial(user),
              child: _AttendanceBody(user: user),
            );
          },
        );
      },
    );
  }
}

class _AttendanceBody extends StatelessWidget {
  const _AttendanceBody({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (BuildContext context, AttendanceState state) {
        return state.maybeWhen<Widget>(
          orElse: () {
            final bool canApproveTeam = RolePermissions.has(
              user.role,
              Permission.attendanceApproveTeam,
            );
            return context.shellMode.isMobile
                ? AttendanceMobileHome(user: user)
                : AttendanceDesktopHome(user: user, canApproveTeam: canApproveTeam);
          },
          loading: () => const Scaffold(
            body: LoadingIndicator(label: 'جارٍ تحميل بيانات الحضور...'),
          ),
          error: (Failure failure) => Scaffold(
            appBar: AppBar(title: const Text('الحضور والانصراف')),
            body: ErrorView(
              title: 'تعذّر تحميل بيانات الحضور',
              message: failure.message,
              onRetry: () => context.read<AttendanceCubit>().loadInitial(user),
            ),
          ),
        );
      },
    );
  }
}
