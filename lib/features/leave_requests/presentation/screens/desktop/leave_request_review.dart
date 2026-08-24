import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/leave_request.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../state/leave_cubit.dart';
import '../../state/leave_state.dart';
import '../../widgets/leave_approval_actions.dart';
import '../../widgets/leave_status_badge.dart';
import '../../widgets/leave_type_selector_items.dart';

/// لوحة مراجعة طلب إجازة جانبية لسطح المكتب — النظير المباشر لـ
/// `report_review_screen.dart` (`features/field_reports/`, Prompt 17):
/// لوحة ثابتة (400px) ضمن التخطيط ثنائي الأعمدة لـ
/// `leave_requests_inbox.dart` بدل صفحة منفصلة. بخلاف
/// `ReportReviewScreen` (تقرأ `reportId` فقط وتحلّه داخلياً من
/// `ReportsInboxData`)، هذه اللوحة تستقبل [request] كاملاً مباشرة من
/// `LeaveRequestsInbox` (يُعاد حلّه هناك بالفعل عند كل إعادة بناء
/// عبر `BlocBuilder`، فيبقى محدَّثاً لحظياً بنفس الأثر دون إعادة حلّ
/// مضاعفة هنا). 🆕
class LeaveRequestReview extends StatelessWidget {
  const LeaveRequestReview({required this.request, super.key, this.onClose});

  final LeaveRequest request;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);

    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(left: BorderSide(color: colors.outlineVariant)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(AvahiSpacing.md),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  leaveTypeLabelAr(request.leaveType),
                  style: context.textTheme.titleLarge,
                ),
              ),
              if (onClose != null)
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
            ],
          ),
          const SizedBox(height: AvahiSpacing.xs),
          LeaveStatusBadge(status: request.status),
          const SizedBox(height: AvahiSpacing.md),
          _DetailRow(label: 'من تاريخ', value: DateFormatter.longDate(request.startDate)),
          _DetailRow(label: 'إلى تاريخ', value: DateFormatter.longDate(request.endDate)),
          _DetailRow(
            label: 'عدد الأيام',
            value: '${request.endDate.difference(request.startDate).inDays + 1}',
          ),
          // ⚠️ معرّف مختصر فقط، لا اسم كامل — حل عرض أسماء كاملة
          // مؤجَّل عمداً لـ `features/users/` (Prompt 26)، بنفس القيد
          // الموثَّق في `LeaveRequestCard`/`worker_row.dart`.
          _DetailRow(
            label: 'الموظف',
            value: request.userId.substring(0, request.userId.length.clamp(0, 12)),
          ),
          _DetailRow(label: 'تاريخ التقديم', value: DateFormatter.longDate(request.createdAt)),
          const SizedBox(height: AvahiSpacing.lg),
          _Section(title: 'سبب الطلب', value: request.reason),
          if (!request.status.isPending && request.reviewNote != null)
            _Section(
              title: request.status.isRejected ? 'سبب الرفض' : 'ملاحظة المراجع',
              value: request.reviewNote,
            ),
          if (request.status.isPending) ...<Widget>[
            const SizedBox(height: AvahiSpacing.xl),
            _ReviewActions(request: request),
          ],
        ],
      ),
    );
  }
}

class _ReviewActions extends StatelessWidget {
  const _ReviewActions({required this.request});

  final LeaveRequest request;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaveCubit, LeaveState>(
      builder: (BuildContext context, LeaveState state) {
        final bool isReviewing = state.dataOrNull?.isReviewing ?? false;

        return LeaveApprovalActions(
          isProcessing: isReviewing,
          onApprove: () async {
            final bool success = await context.read<LeaveCubit>().reviewLeave(
                  request: request,
                  approve: true,
                );
            if (!context.mounted) return;
            context.showSnackBar(
              success ? 'تم اعتماد طلب الإجازة.' : 'تعذّر اعتماد الطلب — حاول مجدداً.',
            );
          },
          onReject: (String reason) async {
            final bool success = await context.read<LeaveCubit>().reviewLeave(
                  request: request,
                  approve: false,
                  reviewNote: reason,
                );
            if (!context.mounted) return;
            context.showSnackBar(
              success ? 'تم رفض طلب الإجازة.' : 'تعذّر رفض الطلب — حاول مجدداً.',
            );
          },
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.value});

  final String title;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = value == null || value!.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: AvahiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: context.textTheme.titleSmall),
          const SizedBox(height: AvahiSpacing.xxs),
          Text(
            isEmpty ? 'بلا بيانات' : value!,
            style: context.textTheme.bodyMedium?.copyWith(
                  color: isEmpty ? context.colors.onSurfaceVariant : null,
                  fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AvahiSpacing.xxs),
      child: Row(
        children: <Widget>[
          Text(label, style: context.textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
