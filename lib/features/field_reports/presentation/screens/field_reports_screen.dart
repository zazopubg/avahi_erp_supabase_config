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
import '../state/report_form_cubit.dart';
import '../state/report_form_state.dart';
import '../state/reports_inbox_cubit.dart';
import '../state/reports_inbox_state.dart';
import 'desktop/field_reports_desktop_home.dart';
import 'mobile/field_reports_mobile_home.dart';

/// نقطة الدخول الوحيدة لكامل ميزة التقارير الميدانية — الشاشة المربوطة
/// فعلياً بـ `RouteNames.fieldReports` ضمن `app_router.dart`.
///
/// يتفرّع العرض حسب [ShellMode] أولاً (بنفس فلسفة `AttendanceScreen`
/// تماماً): [ShellMode.mobile] يعرض دوماً تجربة "العامل الميداني"
/// ([ReportFormCubit] + [FieldReportsMobileHome]) بصرف النظر عن الدور
/// — عامل الحقل يستخدم هاتفه لإنشاء تقاريره، وحتى مشرف يفتح التطبيق من
/// هاتفه يفعل الشيء نفسه غالباً. أما على الشاشات الأوسع (لوحي/سطح
/// مكتب)، فيُفحص [Permission.fieldReportsViewTeam] (`canApproveTeam`)
/// أولاً — إن توفّرت، يُعرض الفرع الإداري الكامل ([ReportsInboxCubit] +
/// [FieldReportsDesktopHome]: وارد لحظي/مراجعة/أرشيف/تصدير)؛ وإلا (عامل
/// حقل يستخدم سطح مكتب/لوحي دون صلاحية إدارية) يُعاد استخدام نفس تجربة
/// [FieldReportsMobileHome] ضمن حاوية بعرض أقصى محدود، تماماً كما تُعيد
/// `AttendanceDesktopHome` استخدام `CheckInScreen` لنفس الحالة.
///
/// ⚠️ ملاحظة معمارية: بخلاف `AttendanceCubit` (كائن واحد يخدم كل
/// الفروع)، هذه الميزة تستخدم **`Cubit`ين منفصلين تماماً** حسب الفرع
/// المُختار أعلاه وليس حسب [ShellMode] وحده — انظر توثيق القرار الكامل
/// في `core/di/features_module.dart` (تعليق `_registerFieldReportsFeature`).
class FieldReportsScreen extends StatelessWidget {
  const FieldReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return authState.maybeWhen<Widget>(
          orElse: () => const Scaffold(body: LoadingIndicator()),
          authenticated: (AppUser user, _) => _RoleBranch(user: user),
        );
      },
    );
  }
}

class _RoleBranch extends StatelessWidget {
  const _RoleBranch({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final bool canApproveTeam = RolePermissions.has(
      user.role,
      Permission.fieldReportsViewTeam,
    );

    final bool showAdminInbox = !context.shellMode.isMobile && canApproveTeam;

    return showAdminInbox
        ? BlocProvider<ReportsInboxCubit>(
            create: (_) => sl<ReportsInboxCubit>()..loadInitial(user),
            child: const _DesktopBody(),
          )
        : BlocProvider<ReportFormCubit>(
            create: (_) => sl<ReportFormCubit>()..loadInitial(user),
            child: _MobileBody(constrainWidth: !context.shellMode.isMobile),
          );
  }
}

class _MobileBody extends StatelessWidget {
  const _MobileBody({required this.constrainWidth});

  /// `true` عند عرض تجربة العامل الميداني فوق شاشة سطح مكتب/لوحي
  /// (بلا صلاحية إدارية) — يُحدّ عرض المحتوى بعرض أقصى مريح للقراءة،
  /// بنفس أسلوب `AttendanceDesktopHome._CheckInScreen`.
  final bool constrainWidth;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportFormCubit, ReportFormState>(
      builder: (BuildContext context, ReportFormState state) {
        final Widget body = state.maybeWhen<Widget>(
          orElse: () => const FieldReportsMobileHome(),
          loading: () => const Scaffold(
            body: LoadingIndicator(label: 'جارٍ تحميل التقارير الميدانية...'),
          ),
          error: (Failure failure) => Scaffold(
            appBar: AppBar(title: const Text('التقارير الميدانية')),
            body: ErrorView(
              title: 'تعذّر تحميل التقارير الميدانية',
              message: failure.message,
              onRetry: () {
                final AuthState authState = context.read<AuthCubit>().state;
                authState.maybeWhen<void>(
                  orElse: () {},
                  authenticated: (AppUser user, _) =>
                      context.read<ReportFormCubit>().loadInitial(user),
                );
              },
            ),
          ),
        );

        if (!constrainWidth) return body;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: body,
          ),
        );
      },
    );
  }
}

class _DesktopBody extends StatelessWidget {
  const _DesktopBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsInboxCubit, ReportsInboxState>(
      builder: (BuildContext context, ReportsInboxState state) {
        return state.maybeWhen<Widget>(
          orElse: () => const FieldReportsDesktopHome(),
          loading: () => const Scaffold(
            body: LoadingIndicator(label: 'جارٍ تحميل التقارير الميدانية...'),
          ),
          error: (Failure failure) => Scaffold(
            appBar: AppBar(title: const Text('التقارير الميدانية')),
            body: ErrorView(
              title: 'تعذّر تحميل التقارير الميدانية',
              message: failure.message,
              onRetry: () {
                final AuthState authState = context.read<AuthCubit>().state;
                authState.maybeWhen<void>(
                  orElse: () {},
                  authenticated: (AppUser user, _) =>
                      context.read<ReportsInboxCubit>().loadInitial(user),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
