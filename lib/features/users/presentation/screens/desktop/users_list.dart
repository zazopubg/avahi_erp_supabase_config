import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/errors/failure.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/enums/user_role.dart';
import '../../../../../navigation/role_labels.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../../../../ui/widgets/common/avahi_text_field.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../../../../ui/widgets/common/error_view.dart';
import '../../../../../ui/widgets/common/loading_indicator.dart';
import '../../../../auth/presentation/state/auth_cubit.dart';
import '../../../../auth/presentation/state/auth_state.dart';
import '../../state/users_cubit.dart';
import '../../state/users_state.dart';
import '../../widgets/permissions_matrix.dart';
import '../../widgets/user_card.dart';
import 'invite_user.dart';
import 'user_details.dart';

/// نقطة الدخول الوحيدة لمسار `RouteNames.users` (`/users`) — بنفس نمط
/// `AnalyticsDashboard`/`MyEquipmentScreen` تماماً: توفّر [UsersCubit]
/// محلياً عبر `sl<UsersCubit>()..loadInitial(user)` عند التحقق من
/// مصادقة المستخدم، ثم تبني تخطيط عمودين (قائمة + بحث/تصفية على
/// اليمين، لوحة تفاصيل [UserDetailsPanel] عند اختيار عضو على اليسار)
/// — بنفس تخطيط `documents_manager.dart`/`equipment_registry.dart`.
///
/// ⚠️ قرار تصميم مهم (لا واجهة هاتف): بنفس منطق `AnalyticsDashboard` —
/// هذه الميزة مُعلَّمة `isDesktopOnly: true` ضمن
/// `AppNavDestinations.users` (`navigation/nav_destinations.dart`).
/// إدارة المستخدمين والأدوار عمل إداري بطبيعته (جداول، مقارنات أدوار،
/// جدول صلاحيات مقروء أفضل على شاشة عريضة) — [PlatformGuard] يمنع
/// الوصول لهذا المسار كاملاً على نافذة ضيقة ويُعيد التوجيه تلقائياً،
/// فلا حاجة لأي فرع عرض هاتف بديل هنا.
class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return authState.maybeWhen<Widget>(
          orElse: () => const Scaffold(body: LoadingIndicator()),
          authenticated: (AppUser user, _) {
            return BlocProvider<UsersCubit>(
              create: (_) => sl<UsersCubit>()..loadInitial(user),
              child: const _UsersListBody(),
            );
          },
        );
      },
    );
  }
}

class _UsersListBody extends StatelessWidget {
  const _UsersListBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersCubit, UsersState>(
      builder: (BuildContext context, UsersState state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('المستخدمون والصلاحيات'),
            actions: <Widget>[
              IconButton(
                tooltip: 'جدول الصلاحيات',
                icon: const Icon(Icons.grid_view_outlined),
                onPressed: () => _showPermissionsMatrix(context),
              ),
              state.dataOrNull?.canInvite ?? false
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AvahiSpacing.sm,
                      ),
                      child: AvahiButton(
                        label: 'دعوة مستخدم',
                        icon: Icons.person_add_alt_outlined,
                        size: AvahiButtonSize.small,
                        onPressed: () => InviteUserDialog.show(
                          context,
                          context.read<UsersCubit>(),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
          body: state.when<Widget>(
            loading: () =>
                const LoadingIndicator(label: 'جارٍ تحميل أعضاء الشركة...'),
            error: (Failure failure) => ErrorView(
              title: 'تعذّر تحميل قائمة المستخدمين',
              message: failure.message,
              onRetry: () {
                final AuthState authState = context.read<AuthCubit>().state;
                authState.maybeWhen<void>(
                  orElse: () {},
                  authenticated: (AppUser user, _) =>
                      context.read<UsersCubit>().loadInitial(user),
                );
              },
            ),
            loaded: (UsersData data) => _UsersListLoaded(data: data),
          ),
        );
      },
    );
  }

  void _showPermissionsMatrix(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AvahiSpacing.lg),
          child: SizedBox(
            width: 900,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'جدول الصلاحيات حسب الدور',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AvahiSpacing.sm),
                const Flexible(
                  child: SingleChildScrollView(child: PermissionsMatrix()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UsersListLoaded extends StatelessWidget {
  const _UsersListLoaded({required this.data});

  final UsersData data;

  @override
  Widget build(BuildContext context) {
    final UsersCubit cubit = context.read<UsersCubit>();
    final List<AppUser> members = data.filteredMembers;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: RefreshIndicator(
            onRefresh: cubit.refresh,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(AvahiSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      AvahiTextField(
                        label: 'بحث بالاسم/الهاتف/المسمى الوظيفي',
                        prefixIcon: Icons.search,
                        onChanged: cubit.setSearchQuery,
                      ),
                      const SizedBox(height: AvahiSpacing.sm),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: AvahiDropdown<UserRole?>(
                              label: 'الدور',
                              value: data.roleFilter,
                              items: <AvahiDropdownItem<UserRole?>>[
                                const AvahiDropdownItem<UserRole?>(
                                  value: null,
                                  label: 'كل الأدوار',
                                ),
                                for (final UserRole role in UserRole.values)
                                  AvahiDropdownItem<UserRole?>(
                                    value: role,
                                    label: role.displayLabel,
                                  ),
                              ],
                              onChanged: cubit.setRoleFilter,
                            ),
                          ),
                          const SizedBox(width: AvahiSpacing.sm),
                          Expanded(
                            child: AvahiDropdown<bool?>(
                              label: 'الحالة',
                              value: data.activeOnly,
                              items: const <AvahiDropdownItem<bool?>>[
                                AvahiDropdownItem<bool?>(
                                  value: true,
                                  label: 'النشطون فقط',
                                ),
                                AvahiDropdownItem<bool?>(
                                  value: false,
                                  label: 'المعطَّلون فقط',
                                ),
                                AvahiDropdownItem<bool?>(
                                  value: null,
                                  label: 'الكل',
                                ),
                              ],
                              onChanged: cubit.setActiveOnlyFilter,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: members.isEmpty
                      ? const EmptyState(
                          icon: Icons.people_outline,
                          title: 'لا يوجد أعضاء مطابقون',
                          message: 'جرّب تعديل البحث أو معايير التصفية.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AvahiSpacing.md,
                          ).copyWith(bottom: AvahiSpacing.md),
                          itemCount: members.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AvahiSpacing.xs),
                          itemBuilder: (BuildContext context, int index) {
                            final AppUser member = members[index];
                            return UserCard(
                              member: member,
                              isSelf: member.id == data.currentUser.id,
                              isSelected:
                                  member.id == data.selectedMemberId,
                              onTap: () => cubit.selectMember(member),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        if (data.selectedMember != null)
          UserDetailsPanel(
            cubit: cubit,
            member: data.selectedMember!,
            data: data,
          ),
      ],
    );
  }
}
