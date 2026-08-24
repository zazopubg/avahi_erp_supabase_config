import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/enums/user_role.dart';
import '../../../../../navigation/role_labels.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../state/users_cubit.dart';
import '../../state/users_state.dart';
import '../../widgets/role_badge.dart';

/// نافذة منبثقة لتعديل دور [member] — `user_details.dart` (زر "تعديل
/// الدور"، يظهر فقط لمن يملك [UsersData.canEditRoles] — admin فقط،
/// انظر `Permission.usersEditRoles`). عند الحفظ يستدعي
/// [UsersCubit.updateMemberRole] مباشرة، والتي تحدّث `company_members.role`
/// فقط — تحديث JWT (`sync-user-claims`) يحدث تلقائياً عبر Database
/// Webhook خلال ثوانٍ، لا استدعاء إضافي من هنا؛ انظر توثيق القرار
/// الكامل في `UpdateMemberRoleUsecase`.
class UserRolesEditDialog extends StatefulWidget {
  const UserRolesEditDialog({
    required this.cubit,
    required this.member,
    super.key,
  });

  final UsersCubit cubit;
  final AppUser member;

  static Future<void> show(
    BuildContext context, {
    required UsersCubit cubit,
    required AppUser member,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => UserRolesEditDialog(cubit: cubit, member: member),
    );
  }

  @override
  State<UserRolesEditDialog> createState() => _UserRolesEditDialogState();
}

class _UserRolesEditDialogState extends State<UserRolesEditDialog> {
  late UserRole _role = widget.member.role;

  Future<void> _submit() async {
    if (_role == widget.member.role) {
      Navigator.of(context).pop();
      return;
    }

    final bool success = await widget.cubit.updateMemberRole(
      member: widget.member,
      role: _role,
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث دور ${widget.member.fullName} إلى ${_role.displayLabel}.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تحديث الدور، حاول مجدداً.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersCubit, UsersState>(
      bloc: widget.cubit,
      builder: (BuildContext context, UsersState state) {
        final bool isSaving = state.dataOrNull?.isSavingRole ?? false;

        return AlertDialog(
          title: Text('تعديل دور ${widget.member.fullName}'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Text('الدور الحالي: '),
                    RoleBadge(role: widget.member.role),
                  ],
                ),
                const SizedBox(height: AvahiSpacing.md),
                AvahiDropdown<UserRole>(
                  label: 'الدور الجديد',
                  value: _role,
                  items: <AvahiDropdownItem<UserRole>>[
                    for (final UserRole role in UserRole.values)
                      AvahiDropdownItem<UserRole>(
                        value: role,
                        label: role.displayLabel,
                      ),
                  ],
                  onChanged: (UserRole? role) {
                    if (role != null) setState(() => _role = role);
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            AvahiButton(
              label: 'إلغاء',
              variant: AvahiButtonVariant.text,
              onPressed: () => Navigator.of(context).pop(),
            ),
            AvahiButton(
              label: 'حفظ',
              isLoading: isSaving,
              onPressed: _submit,
            ),
          ],
        );
      },
    );
  }
}
