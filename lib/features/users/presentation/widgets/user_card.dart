import 'package:flutter/material.dart';

import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../ui/theme/avahi_colors.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import '../../../../ui/widgets/common/avatar.dart';
import '../../../../ui/widgets/common/status_badge.dart';
import 'role_badge.dart';

/// بطاقة عضو مضغوطة — صورة رمزية، الاسم الكامل، شارة الدور، المسمى
/// الوظيفي/الهاتف (إن وُجدا)، وشارة "معطَّل" عند `!isActive` — العنصر
/// البصري الأساسي في `users_list.dart` (سطح المكتب)، بنفس فلسفة
/// `EquipmentCard`/`LeaveRequestCard`.
///
/// مكوّن عرض بحت — [onTap] يفتح `user_details.dart` (اللوحة الجانبية).
class UserCard extends StatelessWidget {
  const UserCard({
    required this.member,
    super.key,
    this.onTap,
    this.isSelected = false,
    this.isSelf = false,
  });

  final AppUser member;
  final VoidCallback? onTap;

  /// عند `true`، تُبرَز البطاقة كمُختارة حالياً (`user_details.dart`
  /// مفتوحة على هذا العضو تحديداً) — `users_list.dart` فقط.
  final bool isSelected;

  /// عند `true`، هذا العضو هو المستخدم الحالي نفسه — تُعرض شارة
  /// "أنت" بدل السماح بفتح إجراءات التعديل عليه (`UsersCubit` يرفض
  /// تعديل/تعطيل النفس دفاعياً أصلاً — انظر توثيق القرار الكامل هناك).
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return Material(
      color: isSelected ? colors.brandContainer.withValues(alpha: 0.35) : colors.surface,
      borderRadius: AvahiRadius.radiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AvahiRadius.radiusMd,
        child: Container(
          padding: const EdgeInsets.all(AvahiSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AvahiRadius.radiusMd,
            border: Border.all(
              color: isSelected ? colors.brand : colors.outlineVariant,
            ),
          ),
          child: Row(
            children: <Widget>[
              Opacity(
                opacity: member.isActive ? 1 : 0.5,
                child: Avatar(
                  imageUrl: member.avatarUrl,
                  name: member.fullName,
                ),
              ),
              const SizedBox(width: AvahiSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            member.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleSmall,
                          ),
                        ),
                        if (isSelf) ...<Widget>[
                          const SizedBox(width: AvahiSpacing.xxs),
                          const StatusBadge(
                            label: 'أنت',
                            status: AvahiStatus.info,
                            dense: true,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AvahiSpacing.xxs),
                    Wrap(
                      spacing: AvahiSpacing.xs,
                      runSpacing: AvahiSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        RoleBadge(role: member.role, dense: true),
                        if (!member.isActive)
                          const StatusBadge(
                            label: 'معطَّل',
                            status: AvahiStatus.danger,
                            dense: true,
                          ),
                        if (member.jobTitle != null)
                          Text(
                            member.jobTitle!,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: colors.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
