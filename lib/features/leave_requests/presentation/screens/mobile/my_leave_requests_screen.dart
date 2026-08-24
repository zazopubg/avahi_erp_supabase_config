import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/errors/failure.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/leave_request.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../../../auth/presentation/state/auth_cubit.dart';
import '../../../../auth/presentation/state/auth_state.dart';
import '../../state/leave_cubit.dart';
import '../../state/leave_state.dart';
import '../../widgets/leave_request_card.dart';
import '../desktop/leave_requests_inbox.dart';
import 'create_leave_request_screen.dart';

/// نقطة الدخول الوحيدة لمسار `RouteNames.leaveRequests` (`/leave-requests`)
/// — بنفس نمط `PunchListScreen` (`features/punch_list/`, Prompt 19)
/// حرفياً: صنف واحد يجمع مسؤوليتين معاً، نقطة الدخول الموحَّدة
/// (تُستورَد مباشرة في `app_router.dart`) **و** واجهة الهاتف/الفرع
/// الشخصي نفسها (`_MyLeaveRequestsBody`) في آن واحد، بينما يُفوَّض
/// عرض سطح المكتب الإداري داخلياً إلى [LeaveRequestsInbox]
/// (`screens/desktop/leave_requests_inbox.dart`) دون أي مسار
/// `go_router` منفصل لها — التزاماً حرفياً بشجرة Prompt 24 المرفقة
/// (لا ملف `leave_requests_screen.dart` جذر منفصل مذكور فيها).
///
/// التفرّع بين الفرعين هنا يتبع منطق `field_reports_screen.dart`
/// (`_RoleBranch`) وليس `PunchListScreen` وحدها: [ShellMode.mobile]
/// يعرض دوماً تجربة "موظف يطّلع على طلباته الشخصية" بصرف النظر عن
/// الدور، بينما على الشاشات الأوسع يُفحص
/// `LeaveData.canApproveTeam` — إن توفّرت يُعرض
/// [LeaveRequestsInbox] الإداري الكامل، وإلا (موظف يستخدم سطح مكتب/
/// لوحي دون صلاحية اعتماد) يُعاد استخدام نفس تجربة الهاتف ضمن حاوية
/// بعرض أقصى محدود، بنفس أسلوب `FieldReportsScreen._MobileBody`.
class MyLeaveRequestsScreen extends StatelessWidget {
  const MyLeaveRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return authState.maybeWhen<Widget>(
          orElse: () => const Scaffold(body: LoadingIndicator()),
          authenticated: (AppUser user, _) {
            return BlocProvider<LeaveCubit>(
              create: (_) => sl<LeaveCubit>()..loadInitial(user),
              child: const _LeaveDispatcher(),
            );
          },
        );
      },
    );
  }
}

class _LeaveDispatcher extends StatelessWidget {
  const _LeaveDispatcher();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaveCubit, LeaveState>(
      builder: (BuildContext context, LeaveState state) {
        final LeaveData? data = state.dataOrNull;
        final bool showAdminInbox =
            !context.shellMode.isMobile && (data?.canApproveTeam ?? false);

        if (showAdminInbox) return const LeaveRequestsInbox();

        final bool constrainWidth = !context.shellMode.isMobile;
        const Widget body = _MyLeaveRequestsBody();

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

class _MyLeaveRequestsBody extends StatelessWidget {
  const _MyLeaveRequestsBody();

  Future<void> _openCreate(BuildContext context) async {
    final LeaveCubit cubit = context.read<LeaveCubit>();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<LeaveCubit>.value(
          value: cubit,
          child: const CreateLeaveRequestScreen(),
        ),
      ),
    );
    // `CreateLeaveRequestScreen` تشارك نفس نسخة [LeaveCubit] (بخلاف
    // `PunchItemCreateScreen` التي تحصل على نسخة `PunchCubit` مستقلة
    // خاصة بها عبر مسار `go_router` منفصل — انظر توثيق القرار الكامل
    // في `MyLeaveRequestsScreen` أعلاه)؛ لذا لا حاجة لاستدعاء
    // `refresh()` هنا: `LeaveCubit.submitLeaveRequest` يُحدّث
    // `myRequests` محلياً فور نجاح التقديم مباشرة.
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaveCubit, LeaveState>(
      builder: (BuildContext context, LeaveState state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('طلبات الإجازة'),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'تقديم طلب إجازة',
                onPressed: () => _openCreate(context),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openCreate(context),
            icon: const Icon(Icons.add),
            label: const Text('طلب إجازة'),
          ),
          body: state.when<Widget>(
            loading: () =>
                const LoadingIndicator(label: 'جارٍ تحميل طلبات الإجازة...'),
            error: (Failure failure) => ErrorView(
              title: 'تعذّر تحميل طلبات الإجازة',
              message: failure.message,
              onRetry: () {
                final AuthState authState = context.read<AuthCubit>().state;
                authState.maybeWhen<void>(
                  orElse: () {},
                  authenticated: (AppUser user, _) =>
                      context.read<LeaveCubit>().loadInitial(user),
                );
              },
            ),
            loaded: (LeaveData data) => data.myRequests.isEmpty
                ? EmptyState(
                    title: 'لا توجد طلبات إجازة بعد',
                    message: 'قدّم أول طلب إجازة عبر زر "طلب إجازة" أدناه.',
                    icon: Icons.beach_access_outlined,
                    actionLabel: 'طلب إجازة',
                    onAction: () => _openCreate(context),
                  )
                : RefreshIndicator(
                    onRefresh: () => context.read<LeaveCubit>().refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AvahiSpacing.md,
                        AvahiSpacing.md,
                        AvahiSpacing.md,
                        AvahiSpacing.xxl,
                      ),
                      itemCount: data.myRequests.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AvahiSpacing.sm),
                      itemBuilder: (BuildContext context, int index) {
                        final LeaveRequest request = data.myRequests[index];
                        return LeaveRequestCard(request: request);
                      },
                    ),
                  ),
          ),
        );
      },
    );
  }
}
