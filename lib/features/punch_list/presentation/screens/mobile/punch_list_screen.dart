import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/errors/failure.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/punch_item.dart';
import '../../../../../navigation/route_names.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../../../auth/presentation/state/auth_cubit.dart';
import '../../../../auth/presentation/state/auth_state.dart';
import '../../state/punch_cubit.dart';
import '../../state/punch_state.dart';
import '../../widgets/punch_item_card.dart';
import '../../widgets/punch_status_filter.dart';
import '../desktop/punch_dashboard.dart';
import 'punch_item_details.dart';

/// نقطة الدخول الوحيدة لمسار `RouteNames.punchList` (`/punch-list`) —
/// بنفس نمط `TasksScreen`/`AttendanceScreen` تماماً: توفّر [PunchCubit]
/// محلياً عبر `sl<PunchCubit>()..loadInitial(user)` ثم تفرّع العرض
/// حسب [ShellMode] فقط.
///
/// ⚠️ قرار تسمية مقصود: شجرة Prompt 19 المرفقة تُسمّي هذا الملف تحديداً
/// `presentation/screens/mobile/punch_list_screen.dart` (بخلاف
/// `TasksScreen`/`AttendanceScreen` اللتين لهما ملف جذر منفصل تحت
/// `presentation/screens/` مباشرة، ثم ملف مختلف الاسم تحت `mobile/`
/// — مثال: `my_tasks_screen.dart`). التزاماً حرفياً بالشجرة المطلوبة
/// دون إضافة ملف جذر إضافي غير مذكور فيها، هذا الصنف [PunchListScreen]
/// يجمع المسؤوليتين معاً: نقطة الدخول الموحَّدة (تُستورَد مباشرة في
/// `app_router.dart`) **و** واجهة الهاتف نفسها (`_PunchListMobileBody`)
/// في آن واحد، بينما يُفوَّض عرض سطح المكتب داخلياً إلى
/// [PunchDashboard] (`screens/desktop/punch_dashboard.dart`) دون أي
/// مسار `go_router` منفصل لها.
class PunchListScreen extends StatelessWidget {
  const PunchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return authState.maybeWhen<Widget>(
          orElse: () => const Scaffold(body: LoadingIndicator()),
          authenticated: (AppUser user, _) {
            return BlocProvider<PunchCubit>(
              create: (_) => sl<PunchCubit>()..loadInitial(user),
              child: const _PunchListDispatcher(),
            );
          },
        );
      },
    );
  }
}

class _PunchListDispatcher extends StatelessWidget {
  const _PunchListDispatcher();

  @override
  Widget build(BuildContext context) {
    // سطح المكتب/الجهاز اللوحي الواسع: لوحة متابعة عبر كل المشاريع —
    // تحميل كسول منفصل تماماً عن حالة `/punch-list` الأساسية
    // (`PunchCubit.loadDashboard`، انظر `PunchDashboard`).
    if (context.shellMode.isDesktop) return const PunchDashboard();
    return const _PunchListMobileBody();
  }
}

class _PunchListMobileBody extends StatefulWidget {
  const _PunchListMobileBody();

  @override
  State<_PunchListMobileBody> createState() => _PunchListMobileBodyState();
}

class _PunchListMobileBodyState extends State<_PunchListMobileBody> {
  Future<void> _openCreate(BuildContext context) async {
    final PunchCubit cubit = context.read<PunchCubit>();
    await context.pushNamed(RouteNames.punchListCreate);
    if (!context.mounted) return;
    // انظر توثيق `PunchItemCreateScreen` — نسخة `PunchCubit` مستقلة
    // هناك، لذا نُحدّث هذه القائمة صراحة عند العودة لضمان ظهور أي
    // عنصر أُنشئ حديثاً.
    await cubit.refresh();
  }

  void _openDetails(BuildContext context, PunchItem item) {
    context.pushNamed(
      RouteNames.punchListDetails,
      extra: PunchItemDetailsRouteArgs(item: item, cubit: context.read<PunchCubit>()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PunchCubit, PunchState>(
      builder: (BuildContext context, PunchState state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('قوائم الملاحظات'),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'تسجيل عيب جديد',
                onPressed: () => _openCreate(context),
              ),
            ],
          ),
          body: state.when<Widget>(
            loading: () =>
                const LoadingIndicator(label: 'جارٍ تحميل قائمة الملاحظات...'),
            error: (Failure failure) => ErrorView(
              title: 'تعذّر تحميل قائمة الملاحظات',
              message: failure.message,
              onRetry: () {
                final AuthState authState = context.read<AuthCubit>().state;
                authState.maybeWhen<void>(
                  orElse: () {},
                  authenticated: (AppUser user, _) =>
                      context.read<PunchCubit>().loadInitial(user),
                );
              },
            ),
            loaded: (PunchData data) => data.project == null
                ? const EmptyState(
                    title: 'لا يوجد مشروع نشط',
                    message: 'لا يوجد مشروع مرتبط بحسابك حالياً.',
                    icon: Icons.folder_off_outlined,
                  )
                : RefreshIndicator(
                    onRefresh: () => context.read<PunchCubit>().refresh(),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AvahiSpacing.md,
                            AvahiSpacing.sm,
                            AvahiSpacing.md,
                            0,
                          ),
                          child: PunchStatusFilter(
                            data: data,
                            onStatusChanged: (status) =>
                                context.read<PunchCubit>().setStatusFilter(status),
                            onSearchChanged: (query) =>
                                context.read<PunchCubit>().setSearchQuery(query),
                            onClearFilters: () =>
                                context.read<PunchCubit>().clearFilters(),
                          ),
                        ),
                        Expanded(
                          child: data.filteredItems.isEmpty
                              ? EmptyState(
                                  title: data.hasActiveFilters
                                      ? 'لا نتائج مطابقة للفلاتر'
                                      : 'لا توجد ملاحظات بعد',
                                  message: data.hasActiveFilters
                                      ? 'جرّب تعديل معايير التصفية.'
                                      : 'سجّل أول عيب أو ملاحظة عبر زر "+" أعلاه.',
                                  icon: Icons.playlist_add_check,
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(AvahiSpacing.md),
                                  itemCount: data.filteredItems.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: AvahiSpacing.sm),
                                  itemBuilder: (BuildContext context, int index) {
                                    final PunchItem item = data.filteredItems[index];
                                    return PunchItemCard(
                                      item: item,
                                      onTap: () => _openDetails(context, item),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
