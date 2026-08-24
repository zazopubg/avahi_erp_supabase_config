import 'package:flutter/material.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/utils/number_formatter.dart';
import '../../../../../domain/entities/equipment.dart';
import '../../../../../domain/enums/equipment_status.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../state/equipment_cubit.dart';
import '../../state/equipment_state.dart';
import '../../widgets/assign_equipment_dialog.dart';
import '../../widgets/equipment_status_badge.dart';
import '../../widgets/usage_hours_chart.dart';

/// لوحة تفاصيل جانبية لمعدة واحدة — تُضمَّن (Embedded) داخل
/// `equipment_registry.dart` (وليست شاشة `go_router` مستقلة، بنفس
/// نمط `DocumentViewerPanel` ضمن `documents_manager.dart` تماماً)،
/// وتُعرض عند اختيار معدة عبر [EquipmentCubit.selectEquipment].
///
/// تعرض: المعلومات الأساسية (النوع/الرقم التسلسلي/المشروع الحالي)،
/// شارة الحالة مع أزرار تغييرها السريعة، سجلي التشغيل (رسم بياني
/// تراكمي عبر `usage_hours_chart.dart`) والصيانة (تاريخ آخر صيانة +
/// الموعد القادم)، وزر فتح [AssignEquipmentDialog].
class EquipmentDetailsPanel extends StatelessWidget {
  const EquipmentDetailsPanel({
    required this.cubit,
    required this.equipment,
    required this.data,
    super.key,
  });

  final EquipmentCubit cubit;
  final Equipment equipment;
  final EquipmentData data;

  Future<void> _openAssignDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AssignEquipmentDialog(
        cubit: cubit,
        equipment: equipment,
        myProjects: data.myProjects,
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    EquipmentStatus status,
  ) async {
    final bool success = await cubit.updateStatus(
      equipment: equipment,
      status: status,
    );
    if (!context.mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تحديث حالة المعدة.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final String? projectName = equipment.projectId == null
        ? null
        : data.projectsById[equipment.projectId]?.name;
    final List<UsageLogEntry> usageLog =
        data.usageLogByEquipmentId[equipment.id] ?? const <UsageLogEntry>[];
    final bool isUpdating = data.isUpdatingStatus;

    return Container(
      width: 360,
      padding: const EdgeInsets.all(AvahiSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          left: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: ListView(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  equipment.name,
                  style: context.textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'إغلاق',
                onPressed: () => cubit.selectEquipment(null),
              ),
            ],
          ),
          if (equipment.nameAr != null && equipment.nameAr != equipment.name)
            Text(
              equipment.nameAr!,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: AvahiSpacing.sm),
          EquipmentStatusBadge(status: equipment.status),
          const SizedBox(height: AvahiSpacing.md),
          _InfoRow(label: 'النوع', value: equipment.type),
          if (equipment.serialNumber != null)
            _InfoRow(label: 'الرقم التسلسلي', value: equipment.serialNumber!),
          _InfoRow(
            label: 'المشروع الحالي',
            value: projectName ?? 'غير مُسندة لمشروع',
          ),
          _InfoRow(
            label: 'ساعات التشغيل التراكمية',
            value: '${NumberFormatter.decimal(equipment.usageHours)} ساعة',
          ),
          if (equipment.purchaseDate != null)
            _InfoRow(
              label: 'تاريخ الشراء',
              value: DateFormatter.shortDate(equipment.purchaseDate!),
            ),
          if (equipment.lastMaintenanceDate != null)
            _InfoRow(
              label: 'آخر صيانة',
              value: DateFormatter.shortDate(equipment.lastMaintenanceDate!),
            ),
          if (equipment.nextMaintenanceDue != null)
            _InfoRow(
              label: 'الصيانة القادمة',
              value: DateFormatter.shortDate(equipment.nextMaintenanceDue!),
              valueColor: data.isOverdue(equipment) ? colors.danger : null,
            ),
          if (equipment.notes != null && equipment.notes!.trim().isNotEmpty)
            _InfoRow(label: 'ملاحظات', value: equipment.notes!),
          const SizedBox(height: AvahiSpacing.md),
          AvahiButton(
            label: 'إسناد لمشروع/مستخدم',
            isFullWidth: true,
            icon: Icons.assignment_ind_outlined,
            onPressed: () => _openAssignDialog(context),
          ),
          const SizedBox(height: AvahiSpacing.sm),
          Text(
            'تغيير الحالة',
            style: context.textTheme.labelLarge,
          ),
          const SizedBox(height: AvahiSpacing.xs),
          Wrap(
            spacing: AvahiSpacing.xs,
            runSpacing: AvahiSpacing.xs,
            children: <Widget>[
              for (final EquipmentStatus status in EquipmentStatus.values)
                if (status != equipment.status)
                  OutlinedButton(
                    onPressed: isUpdating
                        ? null
                        : () => _changeStatus(context, status),
                    child: Text(equipmentStatusVisuals(status).$1),
                  ),
            ],
          ),
          const SizedBox(height: AvahiSpacing.lg),
          Text('سجل التشغيل (هذه الجلسة)', style: context.textTheme.titleSmall),
          const SizedBox(height: AvahiSpacing.sm),
          UsageHoursChart(entries: usageLog),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AvahiSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: context.textTheme.bodyMedium?.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
