import 'package:flutter/material.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_dialog.dart';
import '../../../../../ui/widgets/common/avatar.dart';
import '../../state/users_cubit.dart';
import '../../state/users_state.dart';
import '../../widgets/role_badge.dart';
import 'user_roles_edit.dart';

/// لوحة تفاصيل جانبية لعضو واحد — تُضمَّن (Embedded) داخل
/// `users_list.dart` (وليست شاشة `go_router` مستقلة، بنفس نمط
/// `EquipmentDetailsPanel`/`DocumentViewerPanel`)، وتُعرض عند اختيار
/// عضو عبر [UsersCubit.selectMember].
///
/// تعرض: صورة رمزية + اسم كامل + شارة الدور، بيانات التواصل (هاتف/
/// مسمى وظيفي)، تاريخ الانضمام، ثم إجراءات إدارية حسب صلاحية
/// [UsersData.currentUser] فعلياً: "تعديل الدور" ([UsersData.canEditRoles])
/// و"تفعيل"/"تعطيل" ([UsersData.canDeactivate]) — كلاهما مُعطَّل تماماً
/// (بلا حتى عرض الزر) عندما [isSelf] (المستخدم الحالي نفسه)، بنفس
/// القيد الدفاعي المفروض أيضاً داخل `UsersCubit` نفسها.
class UserDetailsPanel extends StatelessWidget {
  const UserDetailsPanel({
    required this.cubit,
    required this.member,
    required this.data,
    super.key,
  });

  final UsersCubit cubit;
  final AppUser member;
  final UsersData data;

  bool get isSelf => member.id == data.currentUser.id;

  Future<void> _confirmToggleStatus(BuildContext context) async {
    final bool activate = !member.isActive;
    await AvahiDialog.show(
      context,
      title: activate ? 'تفعيل العضو' : 'تعطيل العضو',
      message: activate
          ? 'سيستعيد "${member.fullName}" وصوله الكامل للنظام فوراً.'
          : 'سيفقد "${member.fullName}" وصوله للنظام فوراً — يمكن التراجع لاحقاً بإعادة التفعيل.',
      confirmLabel: activate ? 'تفعيل' : 'تعطيل',
      cancelLabel: 'إلغاء',
      isDestructive: !activate,
      onConfirm: () async {
        Navigator.of(context).pop();
        final bool success = await cubit.updateMemberStatus(
          member: member,
          isActive: activate,
        );
        if (!context.mounted) return;
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذّر تحديث حالة العضو.')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final bool isSavingStatus = data.isSavingStatus;

    return Container(
      width: 360,
      padding: const EdgeInsets.all(AvahiSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(left: BorderSide(color: colors.outlineVariant)),
      ),
      child: ListView(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(member.fullName, style: context.textTheme.titleLarge),
              ),
              IconButton(
                tooltip: 'إغلاق',
                icon: const Icon(Icons.close),
                onPressed: () => cubit.selectMember(null),
              ),
            ],
          ),
          const SizedBox(height: AvahiSpacing.sm),
          Center(
            child: Avatar(
              imageUrl: member.avatarUrl,
              name: member.fullName,
              size: AvatarSize.xlarge,
            ),
          ),
          const SizedBox(height: AvahiSpacing.sm),
          Center(
            child: Wrap(
              spacing: AvahiSpacing.xs,
              alignment: WrapAlignment.center,
              children: <Widget>[
                RoleBadge(role: member.role),
                if (!member.isActive)
                  const _InactiveBadge()
                else if (isSelf)
                  const _SelfBadge(),
              ],
            ),
          ),
          const SizedBox(height: AvahiSpacing.lg),
          _DetailRow(
            icon: Icons.work_outline,
            label: 'المسمى الوظيفي',
            value: member.jobTitle ?? '—',
          ),
          _DetailRow(
            icon: Icons.phone_outlined,
            label: 'الهاتف',
            value: member.phone ?? '—',
          ),
          _DetailRow(
            icon: Icons.event_available_outlined,
            label: 'تاريخ الانضمام',
            value: DateFormatter.shortDate(member.joinedAt),
          ),
          const SizedBox(height: AvahiSpacing.lg),
          if (data.canEditRoles && !isSelf)
            AvahiButton(
              label: 'تعديل الدور',
              icon: Icons.manage_accounts_outlined,
              variant: AvahiButtonVariant.secondary,
              isFullWidth: true,
              onPressed: () => UserRolesEditDialog.show(
                context,
                cubit: cubit,
                member: member,
              ),
            ),
          if (data.canDeactivate && !isSelf) ...<Widget>[
            const SizedBox(height: AvahiSpacing.sm),
            AvahiButton(
              label: member.isActive ? 'تعطيل العضو' : 'إعادة تفعيل العضو',
              icon: member.isActive
                  ? Icons.block_outlined
                  : Icons.check_circle_outline,
              variant: member.isActive
                  ? AvahiButtonVariant.danger
                  : AvahiButtonVariant.primary,
              isFullWidth: true,
              isLoading: isSavingStatus,
              onPressed: () => _confirmToggleStatus(context),
            ),
          ],
          if (isSelf) ...<Widget>[
            const SizedBox(height: AvahiSpacing.sm),
            Text(
              'لا يمكنك تعديل دورك أو تعطيل حسابك بنفسك — اطلب من مدير نظام آخر إجراء ذلك.',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AvahiSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: AvahiSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: context.textTheme.labelSmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                Text(value, style: context.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InactiveBadge extends StatelessWidget {
  const _InactiveBadge();

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: colors.dangerContainer,
      label: Text(
        'معطَّل',
        style: TextStyle(color: colors.onDangerContainer, fontSize: 11),
      ),
    );
  }
}

class _SelfBadge extends StatelessWidget {
  const _SelfBadge();

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: colors.infoContainer,
      label: Text(
        'أنت',
        style: TextStyle(color: colors.onInfoContainer, fontSize: 11),
      ),
    );
  }
}
