import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/leave_request.dart';
import '../../../../../domain/enums/leave_status.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_dropdown.dart';
import '../../../../../ui/widgets/desktop/data_grid_rtl.dart';
import '../../state/leave_cubit.dart';
import '../../state/leave_state.dart';
import '../../widgets/leave_status_badge.dart';
import '../../widgets/leave_type_selector_items.dart';
import 'leave_request_review.dart';

/// عرض "وارد طلبات الإجازة" لمشرف/مدير يملك
/// [Permission.leaveRequestApproveTeam] — تُعرض عبر
/// `MyLeaveRequestsScreen._LeaveDispatcher` (سطح المكتب فقط)، بنفس
/// نمط `ReportsInbox` (`features/field_reports/`, Prompt 17) تماماً:
/// تخطيط ثنائي الأعمدة — [DataGridRtl] + تصفية (حالة/موظف) في عمود
/// موسَّع، و[LeaveRequestReview] ثابتة على اليسار تعرض تفاصيل الطلب
/// المُختار. الاختيار الحالي (`_selectedRequestId`) حالة عرض محلية
/// بحتة (وليست ضمن [LeaveData])، بنفس قرار `ReportsInbox` تماماً.
///
/// ⚠️ بخلاف `ReportsInbox` (لحظي/Realtime عبر
/// `WatchProjectReportsUsecase`)، هذه القائمة **ثابتة** حتى
/// `LeaveCubit.refresh()` التالي (سحب للتحديث يدوي أو بعد
/// اعتماد/رفض طلب) — لا `watchXxx` ضمن `ILeaveRepository` (انظر
/// توثيق القرار الكامل في `LeaveCubit`).
class LeaveRequestsInbox extends StatefulWidget {
  const LeaveRequestsInbox({super.key});

  @override
  State<LeaveRequestsInbox> createState() => _LeaveRequestsInboxState();
}

class _LeaveRequestsInboxState extends State<LeaveRequestsInbox> {
  String? _selectedRequestId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaveCubit, LeaveState>(
      builder: (BuildContext context, LeaveState state) {
        final LeaveData? data = state.dataOrNull;
        if (data == null) return const Center(child: CircularProgressIndicator());

        final List<LeaveRequest> filtered = data.filteredCompanyRequests;
        LeaveRequest? selected;
        if (_selectedRequestId != null) {
          for (final LeaveRequest r in data.companyRequests) {
            if (r.id == _selectedRequestId) {
              selected = r;
              break;
            }
          }
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AvahiSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text('وارد طلبات الإجازة', style: context.textTheme.titleLarge),
                        const Spacer(),
                        _PendingCountChip(count: data.pendingApprovalCount),
                      ],
                    ),
                    const SizedBox(height: AvahiSpacing.md),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AvahiDropdown<LeaveStatus?>(
                            label: 'الحالة',
                            value: data.statusFilter,
                            items: <AvahiDropdownItem<LeaveStatus?>>[
                              const AvahiDropdownItem<LeaveStatus?>(
                                value: null,
                                label: 'كل الحالات',
                              ),
                              ...LeaveStatus.values.map(
                                (LeaveStatus s) => AvahiDropdownItem<LeaveStatus?>(
                                  value: s,
                                  label: switch (s) {
                                    LeaveStatus.pending => 'بانتظار الاعتماد',
                                    LeaveStatus.approved => 'مقبولة',
                                    LeaveStatus.rejected => 'مرفوضة',
                                    LeaveStatus.cancelled => 'ملغاة',
                                  },
                                ),
                              ),
                            ],
                            onChanged: (LeaveStatus? value) =>
                                context.read<LeaveCubit>().setStatusFilter(value),
                          ),
                        ),
                        const SizedBox(width: AvahiSpacing.md),
                        Expanded(
                          child: AvahiDropdown<String?>(
                            label: 'الموظف',
                            value: data.employeeFilter,
                            items: <AvahiDropdownItem<String?>>[
                              const AvahiDropdownItem<String?>(
                                value: null,
                                label: 'كل الموظفين',
                              ),
                              ...data.distinctEmployeeIds.map(
                                (String id) => AvahiDropdownItem<String?>(
                                  value: id,
                                  label: id.substring(0, id.length.clamp(0, 8)),
                                ),
                              ),
                            ],
                            onChanged: (String? value) =>
                                context.read<LeaveCubit>().setEmployeeFilter(value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AvahiSpacing.md),
                    Expanded(
                      child: DataGridRtl<LeaveRequest>(
                        rowKeyOf: (LeaveRequest r) => r.id,
                        onRowTap: (LeaveRequest r) =>
                            setState(() => _selectedRequestId = r.id),
                        emptyTitle: 'لا توجد طلبات إجازة مطابقة',
                        emptyIcon: Icons.inbox_outlined,
                        columns: <DataGridColumn<LeaveRequest>>[
                          DataGridColumn<LeaveRequest>(
                            label: 'النوع',
                            cellBuilder: (_, LeaveRequest r) =>
                                Text(leaveTypeLabelAr(r.leaveType)),
                          ),
                          DataGridColumn<LeaveRequest>(
                            label: 'الموظف',
                            cellBuilder: (_, LeaveRequest r) => Text(
                              r.userId.substring(0, r.userId.length.clamp(0, 8)),
                            ),
                          ),
                          DataGridColumn<LeaveRequest>(
                            label: 'المدى الزمني',
                            flex: 2,
                            cellBuilder: (_, LeaveRequest r) => Text(
                              '${r.startDate.day}/${r.startDate.month} - ${r.endDate.day}/${r.endDate.month}',
                            ),
                          ),
                          DataGridColumn<LeaveRequest>(
                            label: 'الحالة',
                            cellBuilder: (_, LeaveRequest r) =>
                                LeaveStatusBadge(status: r.status, dense: true),
                          ),
                        ],
                        rows: filtered,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (selected != null)
              LeaveRequestReview(
                request: selected,
                onClose: () => setState(() => _selectedRequestId = null),
              ),
          ],
        );
      },
    );
  }
}

class _PendingCountChip extends StatelessWidget {
  const _PendingCountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Chip(
      avatar: const Icon(Icons.hourglass_top, size: 16),
      label: Text('$count بانتظار الاعتماد'),
      backgroundColor: colors.tertiaryContainer,
    );
  }
}
