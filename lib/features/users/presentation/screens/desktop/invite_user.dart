import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/validators.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/enums/user_role.dart';
import '../../../../../navigation/role_labels.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../../../../ui/widgets/common/avahi_text_field.dart';
import '../../state/users_cubit.dart';
import '../../state/users_state.dart';

/// نافذة منبثقة لدعوة مستخدم جديد إلى الشركة — `users_list.dart`
/// (زر "دعوة مستخدم"، يظهر فقط لمن يملك [UsersData.canInvite]). عند
/// الإرسال يستدعي [UsersCubit.inviteUser]، والتي بدورها تستدعي Edge
/// Function `invite-user` (`service_role`) — انظر توثيق القرار الكامل
/// في `IUserRepository.inviteUser`.
///
/// ⚠️ قرار تصميم (الدور المُقترَح لا يتجاوز دور الداعي نفسه): القائمة
/// المنسدلة هنا تعرض فقط الأدوار التي رتبتها (`UserRole.rank`) لا
/// تتجاوز دور [UsersData.currentUser] — دفاعية على مستوى الواجهة قبل
/// حتى وصول الطلب لتحقق `invite-user` الخادمي المطابق (منع "ترقية"
/// دور المدعو فوق دور الداعي نفسه، سواء بالخطأ أو عمداً).
class InviteUserDialog extends StatefulWidget {
  const InviteUserDialog({required this.cubit, super.key});

  final UsersCubit cubit;

  static Future<void> show(BuildContext context, UsersCubit cubit) {
    return showDialog<void>(
      context: context,
      builder: (_) => InviteUserDialog(cubit: cubit),
    );
  }

  @override
  State<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<InviteUserDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  UserRole _role = UserRole.worker;

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _jobTitleController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final AppUser? invited = await widget.cubit.inviteUser(
      email: _emailController.text,
      fullName: _fullNameController.text,
      role: _role,
      jobTitle: _jobTitleController.text,
      phone: _phoneController.text,
    );

    if (!mounted) return;
    if (invited != null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال دعوة إلى ${invited.fullName}.')),
      );
    }
    // عند الفشل: `UsersData.inviteErrorMessage` يُعرض ضمن نفس الحوار
    // عبر `BlocBuilder` أدناه (بلا إغلاق النافذة) — بنفس نمط
    // `LeaveData.submitErrorMessage` في `create_leave_request_screen.dart`.
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersCubit, UsersState>(
      bloc: widget.cubit,
      builder: (BuildContext context, UsersState state) {
        final UsersData? data = state.dataOrNull;
        final bool isInviting = data?.isInviting ?? false;
        final List<UserRole> selectableRoles = data == null
            ? UserRole.values
            : UserRole.values
                .where((UserRole r) => r.rank <= data.currentUser.role.rank)
                .toList(growable: false);

        return AlertDialog(
          title: const Text('دعوة مستخدم جديد'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AvahiTextField(
                    controller: _fullNameController,
                    label: 'الاسم الكامل',
                    validator: Validators.required,
                  ),
                  const SizedBox(height: AvahiSpacing.sm),
                  AvahiTextField(
                    controller: _emailController,
                    label: 'البريد الإلكتروني',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: AvahiSpacing.sm),
                  AvahiDropdown<UserRole>(
                    label: 'الدور',
                    value: _role,
                    items: <AvahiDropdownItem<UserRole>>[
                      for (final UserRole role in selectableRoles)
                        AvahiDropdownItem<UserRole>(
                          value: role,
                          label: role.displayLabel,
                        ),
                    ],
                    onChanged: (UserRole? role) {
                      if (role != null) setState(() => _role = role);
                    },
                  ),
                  const SizedBox(height: AvahiSpacing.sm),
                  AvahiTextField(
                    controller: _jobTitleController,
                    label: 'المسمى الوظيفي (اختياري)',
                  ),
                  const SizedBox(height: AvahiSpacing.sm),
                  AvahiTextField(
                    controller: _phoneController,
                    label: 'الهاتف (اختياري)',
                    keyboardType: TextInputType.phone,
                  ),
                  if (data?.inviteErrorMessage != null) ...<Widget>[
                    const SizedBox(height: AvahiSpacing.sm),
                    Text(
                      data!.inviteErrorMessage!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: <Widget>[
            AvahiButton(
              label: 'إلغاء',
              variant: AvahiButtonVariant.text,
              onPressed: () => Navigator.of(context).pop(),
            ),
            AvahiButton(
              label: 'إرسال الدعوة',
              isLoading: isInviting,
              onPressed: _submit,
            ),
          ],
        );
      },
    );
  }
}
