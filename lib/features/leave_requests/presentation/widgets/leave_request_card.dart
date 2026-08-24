import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../domain/entities/leave_request.dart';
import '../../../../ui/theme/avahi_radius.dart';
import '../../../../ui/theme/avahi_spacing.dart';
import 'leave_status_badge.dart';
import 'leave_type_selector_items.dart';

/// بطاقة طلب إجازة مضغوطة — العنصر البصري المشترك بين
/// `my_leave_requests_screen.dart` (الهاتف، سجل طلبات المستخدم نفسه)
/// و`leave_requests_inbox.dart` (سطح المكتب، صفوف الوارد قبل التحويل
/// لصف [DataGridRtl] كامل)، بنفس فلسفة `PunchItemCard`/`ReportCard`
/// تماماً. 🆕
///
/// تعرض نوع الإجازة، شارة الحالة، المدى الزمني، وعدد الأيام. [showUser]
/// يُظهر معرّف مقدّم الطلب مختصراً — `true` فقط ضمن
/// `leave_requests_inbox.dart` (طلبات عدة موظفين معاً)، `false` ضمن
/// `my_leave_requests_screen.dart` (مقدّم الطلب معروف أصلاً من سياق
/// الشاشة، بنفس قيد `PunchItemCard.projectLabel` الاختياري).
///
/// مكوّن عرض بحت — [onTap] اختياري لفتح تفاصيل/مراجعة الطلب.
class LeaveRequestCard extends StatelessWidget {
  const LeaveRequestCard({
    required this.request,
    super.key,
    this.onTap,
    this.showUser = false,
  });

  final LeaveRequest request;
  final VoidCallback? onTap;
  final bool showUser;

  int get _durationDays =>
      request.endDate.difference(request.startDate).inDays + 1;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: AvahiRadius.radiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AvahiRadius.radiusMd,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AvahiSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AvahiRadius.radiusMd,
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.event_busy_outlined, size: 18, color: context.colors.primary),
                  const SizedBox(width: AvahiSpacing.xs),
                  Expanded(
                    child: Text(
                      leaveTypeLabelAr(request.leaveType),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall,
                    ),
                  ),
                  LeaveStatusBadge(status: request.status, dense: true),
                ],
              ),
              const SizedBox(height: AvahiSpacing.xs),
              Row(
                children: <Widget>[
                  Icon(Icons.date_range_outlined, size: 14, color: context.colors.onSurfaceVariant),
                  const SizedBox(width: AvahiSpacing.xxs),
                  Expanded(
                    child: Text(
                      '${DateFormatter.shortDate(request.startDate)} - '
                      '${DateFormatter.shortDate(request.endDate)} '
                      '($_durationDays يوم)',
                      style: context.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (showUser) ...<Widget>[
                const SizedBox(height: AvahiSpacing.xxs),
                Row(
                  children: <Widget>[
                    Icon(Icons.person_outline, size: 14, color: context.colors.onSurfaceVariant),
                    const SizedBox(width: AvahiSpacing.xxs),
                    // ⚠️ عرض معرّف مختصر فقط، لا اسم كامل — حل عرض
                    // أسماء كاملة مؤجَّل عمداً لـ `features/users/`
                    // (Prompt 26)، بنفس القيد الموثَّق في
                    // `worker_row.dart` (`features/attendance/`).
                    Text(
                      'موظف: ${request.userId.substring(0, request.userId.length.clamp(0, 8))}…',
                      style: context.textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
              if (request.reason != null && request.reason!.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: AvahiSpacing.xxs),
                Text(
                  request.reason!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (request.status.isRejected &&
                  request.reviewNote != null &&
                  request.reviewNote!.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: AvahiSpacing.xxs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.info_outline, size: 14, color: context.colors.error),
                    const SizedBox(width: AvahiSpacing.xxs),
                    Expanded(
                      child: Text(
                        'سبب الرفض: ${request.reviewNote}',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
