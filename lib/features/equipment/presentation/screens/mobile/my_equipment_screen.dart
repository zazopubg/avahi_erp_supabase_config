import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/errors/failure.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/equipment.dart';
import '../../../../../navigation/route_names.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../../../auth/presentation/state/auth_cubit.dart';
import '../../../../auth/presentation/state/auth_state.dart';
import '../../state/equipment_cubit.dart';
import '../../state/equipment_state.dart';
import '../../widgets/equipment_card.dart';
import '../desktop/equipment_registry.dart';
import 'log_usage_screen.dart';

/// نقطة الدخول الوحيدة لمسار `RouteNames.equipment` (`/equipment`) —
/// بنفس نمط `PunchListScreen`/`DocumentsListScreen` تماماً: توفّر
/// [EquipmentCubit] محلياً عبر `sl<EquipmentCubit>()..loadInitial(user)`
/// ثم تفرّع العرض حسب [ShellMode] فقط — سطح المكتب/الجهاز اللوحي
/// الواسع يُفوَّض بالكامل إلى [EquipmentRegistry]
/// (`screens/desktop/equipment_registry.dart`)، بينما يبقى هذا الملف
/// نفسه (`mobile/my_equipment_screen.dart`) يجمع المسؤوليتين معاً:
/// نقطة الدخول الموحَّدة **و** واجهة الهاتف نفسها.
///
/// ⚠️ قرار تصميم مهم (My Equipment فقط، لا سجل الشركة كاملاً): بخلاف
/// `equipment_registry.dart` (سجل الشركة الكامل مع إسناد/تحديث حالة)،
/// واجهة الهاتف هنا تعرض حصراً [EquipmentData.myEquipment] (المعدات
/// المُسندة للمستخدم الحالي فقط) — العامل الميداني على الهاتف يحتاج
/// فقط متابعة معداته هو، وتسجيل ساعات تشغيلها، وليس إدارة سجل الشركة
/// كاملاً (إسناد/إلغاء إسناد لمستخدمين آخرين — إجراء إداري يبقى حصراً
/// على سطح المكتب في `equipment_registry.dart`).
class MyEquipmentScreen extends StatelessWidget {
  const MyEquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return authState.maybeWhen<Widget>(
          orElse: () => const Scaffold(body: LoadingIndicator()),
          authenticated: (AppUser user, _) {
            return BlocProvider<EquipmentCubit>(
              create: (_) => sl<EquipmentCubit>()..loadInitial(user),
              child: const _EquipmentDispatcher(),
            );
          },
        );
      },
    );
  }
}

class _EquipmentDispatcher extends StatelessWidget {
  const _EquipmentDispatcher();

  @override
  Widget build(BuildContext context) {
    if (context.shellMode.isDesktop) return const EquipmentRegistry();
    return const _MyEquipmentMobileBody();
  }
}

class _MyEquipmentMobileBody extends StatelessWidget {
  const _MyEquipmentMobileBody();

  void _openLogUsage(BuildContext context, Equipment equipment) {
    context.pushNamed(
      RouteNames.equipmentLogUsage,
      extra: LogUsageRouteArgs(
        equipment: equipment,
        cubit: context.read<EquipmentCubit>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EquipmentCubit, EquipmentState>(
      builder: (BuildContext context, EquipmentState state) {
        return Scaffold(
          appBar: AppBar(title: const Text('معداتي')),
          body: state.when<Widget>(
            loading: () =>
                const LoadingIndicator(label: 'جارٍ تحميل المعدات...'),
            error: (Failure failure) => ErrorView(
              title: 'تعذّر تحميل المعدات',
              message: failure.message,
              onRetry: () {
                final AuthState authState = context.read<AuthCubit>().state;
                authState.maybeWhen<void>(
                  orElse: () {},
                  authenticated: (AppUser user, _) =>
                      context.read<EquipmentCubit>().loadInitial(user),
                );
              },
            ),
            loaded: (EquipmentData data) => RefreshIndicator(
              onRefresh: () => context.read<EquipmentCubit>().refresh(),
              child: data.myEquipment.isEmpty
                  ? ListView(
                      children: const <Widget>[
                        SizedBox(height: AvahiSpacing.xxl),
                        EmptyState(
                          title: 'لا توجد معدات مُسندة إليك بعد',
                          message:
                              'ستظهر هنا المعدات التي يُسندها لك مدير المشروع.',
                          icon: Icons.construction_outlined,
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AvahiSpacing.md),
                      itemCount: data.myEquipment.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AvahiSpacing.sm),
                      itemBuilder: (BuildContext context, int index) {
                        final Equipment equipment = data.myEquipment[index];
                        return EquipmentCard(
                          equipment: equipment,
                          projectLabel: equipment.projectId == null
                              ? null
                              : data.projectsById[equipment.projectId]?.name,
                          trailing: AvahiButton(
                            label: 'تسجيل ساعات',
                            size: AvahiButtonSize.small,
                            variant: AvahiButtonVariant.secondary,
                            icon: Icons.add_task_outlined,
                            onPressed: () => _openLogUsage(context, equipment),
                          ),
                          onTap: () => _openLogUsage(context, equipment),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}
