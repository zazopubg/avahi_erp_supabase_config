import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/auth/presentation/state/auth_cubit.dart';
import '../../../../features/auth/presentation/state/auth_state.dart';
import '../../../../navigation/role_labels.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_dialog.dart';
import '../../../../ui/widgets/common/avatar.dart';

/// الملف الشخصي — تقرأ [AppUser]/[Company] الحاليين مباشرة من
/// `AuthCubit.state` (بنفس نمط `home_screen.dart`، Prompt 14) — لا
/// تحتاج `SettingsCubit` إطلاقاً (انظر توثيق القرار في
/// `settings_screen.dart`)، ولا تعديل بيانات فعلياً في هذه الخطوة
/// (لا `EditProfileUsecase` مبني بعد ضمن `domain/usecases/` — يبقى
/// نطاق ميزة `users/` الكاملة لاحقاً؛ هذه الشاشة عرض + تسجيل خروج).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (BuildContext context, AuthState state) {
          return state.maybeWhen<Widget>(
            authenticated: (user, company) => _ProfileBody(
              userName: user.fullName,
              jobTitle: user.jobTitle,
              phone: user.phone,
              avatarUrl: user.avatarUrl,
              roleLabel: user.role.displayLabel,
              companyName: company.nameAr ?? company.name,
            ),
            orElse: () => const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.userName,
    required this.jobTitle,
    required this.phone,
    required this.avatarUrl,
    required this.roleLabel,
    required this.companyName,
  });

  final String userName;
  final String? jobTitle;
  final String? phone;
  final String? avatarUrl;
  final String roleLabel;
  final String companyName;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return ListView(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      children: <Widget>[
        Center(
          child: Column(
            children: <Widget>[
              Avatar(imageUrl: avatarUrl, name: userName, size: AvatarSize.xlarge),
              const SizedBox(height: AvahiSpacing.sm),
              Text(
                userName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (jobTitle != null && jobTitle!.isNotEmpty) ...<Widget>[
                const SizedBox(height: AvahiSpacing.xxs),
                Text(
                  jobTitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AvahiSpacing.lg),
        _InfoTile(icon: Icons.badge_outlined, label: 'الدور', value: roleLabel),
        _InfoTile(
          icon: Icons.apartment_outlined,
          label: 'الشركة',
          value: companyName,
        ),
        if (phone != null && phone!.isNotEmpty)
          _InfoTile(icon: Icons.phone_outlined, label: 'الهاتف', value: phone!),
        const SizedBox(height: AvahiSpacing.xl),
        OutlinedButton.icon(
          onPressed: () => _confirmLogout(context),
          icon: const Icon(Icons.logout),
          label: const Text('تسجيل الخروج'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.danger,
            side: BorderSide(color: colors.danger),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    final AuthCubit authCubit = context.read<AuthCubit>();
    AvahiDialog.show(
      context,
      title: 'تسجيل الخروج',
      message: 'هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟',
      confirmLabel: 'تسجيل الخروج',
      cancelLabel: 'إلغاء',
      isDestructive: true,
      onConfirm: () {
        Navigator.of(context).pop();
        authCubit.logout();
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return ListTile(
      leading: Icon(icon, color: colors.onSurfaceVariant),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
