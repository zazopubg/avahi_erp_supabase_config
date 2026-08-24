import 'package:flutter/material.dart';

import '../../../../domain/entities/app_user.dart';
import '../../../../navigation/role_labels.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avahi_button.dart';
import '../../../../ui/widgets/common/avatar.dart';
import '../../../../ui/widgets/common/empty_state.dart';
import '../../../../ui/widgets/common/loading_indicator.dart';

/// منتقي إضافة عضو إلى مشروع — يعرض [availableMembers] (أعضاء الشركة
/// غير المُسندين بعد لهذا المشروع، عبر
/// `ProjectsCubit.loadAvailableMembers`) كقائمة قابلة للاختيار، كل
/// عضو مع اسمه ودوره في الشركة ([UserRoleLabelX.displayLabel]).
///
/// ⚠️ قرار تصميم: لا يوجد "دور خاص بالمشروع" منفصل عن دور الشركة
/// (`public.project_members` لا يحمل عمود `role` — انظر توثيق
/// [IProjectRepository.addProjectMember])؛ هذا المنتقي يعرض دور
/// الشركة الحالي **للعِلم فقط** عند الاختيار، وليس كحقل قابل للتعديل.
///
/// مكوّن عرض بحت — [onMemberSelected] هو من ينفّذ فعلياً
/// `ProjectsCubit.addMember` من الشاشة المستدعية (`project_members.dart`).
class MemberRoleSelector extends StatelessWidget {
  const MemberRoleSelector({
    required this.availableMembers,
    required this.isLoading,
    required this.onMemberSelected,
    super.key,
    this.isSubmitting = false,
  });

  final List<AppUser> availableMembers;
  final bool isLoading;
  final bool isSubmitting;
  final ValueChanged<AppUser> onMemberSelected;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AvahiSpacing.lg),
        child: LoadingIndicator(label: 'جارٍ تحميل أعضاء الشركة المتاحين...'),
      );
    }

    if (availableMembers.isEmpty) {
      return const EmptyState(
        title: 'لا يوجد أعضاء متاحون',
        message: 'كل أعضاء الشركة النشطين مُسندون بالفعل إلى هذا المشروع.',
        icon: Icons.people_outline,
      );
    }

    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: AvahiSpacing.xs),
      itemCount: availableMembers.length,
      separatorBuilder: (_, __) => const SizedBox(height: AvahiSpacing.xs),
      itemBuilder: (BuildContext context, int index) {
        final AppUser member = availableMembers[index];
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: AvahiRadius.radiusMd,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AvahiSpacing.sm,
            vertical: AvahiSpacing.xs,
          ),
          child: Row(
            children: <Widget>[
              Avatar(imageUrl: member.avatarUrl, name: member.fullName, size: AvatarSize.small),
              const SizedBox(width: AvahiSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      member.fullName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      member.jobTitle ?? member.role.displayLabel,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              AvahiButton(
                label: 'إضافة',
                variant: AvahiButtonVariant.secondary,
                size: AvahiButtonSize.small,
                isLoading: isSubmitting,
                onPressed: isSubmitting ? null : () => onMemberSelected(member),
              ),
            ],
          ),
        );
      },
    );
  }
}
