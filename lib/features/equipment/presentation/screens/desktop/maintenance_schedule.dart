import 'package:flutter/material.dart';

import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../domain/entities/equipment.dart';
import '../../../../../domain/enums/equipment_status.dart';
import '../../../../../ui/theme/avahi_colors.dart';
import '../../../../../ui/theme/avahi_spacing.dart';
import '../../../../../ui/widgets/common/avahi_button.dart';
import '../../../../../ui/widgets/common/empty_state.dart';
import '../../state/equipment_cubit.dart';
import '../../state/equipment_state.dart';
import '../../widgets/equipment_card.dart';

/// جدول المعدات المستحقة للصيانة الدورية — يُضمَّن ضمن
/// `equipment_registry.dart` كوضع عرض بديل (تبديل عبر الأزرار
/// المقسَّمة أعلى الشجرة، بنفس نمط تبديل "القائمة/الفئات" ضمن
/// `documents_manager.dart`)، وليس مساراً `go_router` مستقلاً.
///
/// المصدر: [EquipmentData.maintenanceDueEquipment] (معدات مقترب أو
/// متجاوز موعد صيانتها القادمة خلال 14 يوماً — انظر توثيق قاعدة
/// الحساب الكاملة هناك)، مقسّمة هنا بصرياً إلى قسمين: "متأخرة" (لون
/// خطر) و"مستحقة قريباً" (لون تحذيري).
class MaintenanceSchedule extends StatelessWidget {
  const MaintenanceSchedule({
    required this.cubit,
    required this.data,
    super.key,
  });

  final EquipmentCubit cubit;
  final EquipmentData data;

  Future<void> _sendToMaintenance(
    BuildContext context,
    Equipment equipment,
  ) async {
    final bool success = await cubit.updateStatus(
      equipment: equipment,
      status: EquipmentStatus.maintenance,
    );
    if (!context.mounted || success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذّر تحديث حالة المعدة.')),
    );
  }

  Future<void> _completeMaintenance(
    BuildContext context,
    Equipment equipment,
  ) async {
    final bool success = await cubit.updateStatus(
      equipment: equipment,
      status: EquipmentStatus.available,
    );
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم تحديث الحالة إلى "متاحة". ملاحظة: تاريخ الصيانة القادمة '
            'يتطلب تحديثاً يدوياً منفصلاً حتى تتوفر عملية خادم مخصّصة لذلك.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تحديث حالة المعدة.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AvahiColors colors = AvahiColors.of(Theme.of(context).brightness);
    final List<Equipment> due = data.maintenanceDueEquipment;

    if (due.isEmpty) {
      return const EmptyState(
        title: 'لا توجد صيانة مستحقة',
        message: 'كل المعدات النشطة ضمن الجدول الزمني المتوقّع حالياً.',
        icon: Icons.verified_outlined,
      );
    }

    final List<Equipment> overdue = due.where(data.isOverdue).toList();
    final List<Equipment> upcoming =
        due.where((Equipment e) => !data.isOverdue(e)).toList();

    return ListView(
      padding: const EdgeInsets.all(AvahiSpacing.md),
      children: <Widget>[
        if (overdue.isNotEmpty) ...<Widget>[
          _SectionHeader(
            label: 'متأخرة (${overdue.length})',
            color: colors.danger,
          ),
          const SizedBox(height: AvahiSpacing.xs),
          for (final Equipment equipment in overdue)
            Padding(
              padding: const EdgeInsets.only(bottom: AvahiSpacing.sm),
              child: _MaintenanceRow(
                equipment: equipment,
                data: data,
                onSendToMaintenance: () =>
                    _sendToMaintenance(context, equipment),
                onCompleteMaintenance: () =>
                    _completeMaintenance(context, equipment),
              ),
            ),
          const SizedBox(height: AvahiSpacing.md),
        ],
        if (upcoming.isNotEmpty) ...<Widget>[
          _SectionHeader(
            label: 'مستحقة قريباً (${upcoming.length})',
            color: colors.warning,
          ),
          const SizedBox(height: AvahiSpacing.xs),
          for (final Equipment equipment in upcoming)
            Padding(
              padding: const EdgeInsets.only(bottom: AvahiSpacing.sm),
              child: _MaintenanceRow(
                equipment: equipment,
                data: data,
                onSendToMaintenance: () =>
                    _sendToMaintenance(context, equipment),
                onCompleteMaintenance: () =>
                    _completeMaintenance(context, equipment),
              ),
            ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: AvahiSpacing.xs),
        Text(
          label,
          style: context.textTheme.titleSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _MaintenanceRow extends StatelessWidget {
  const _MaintenanceRow({
    required this.equipment,
    required this.data,
    required this.onSendToMaintenance,
    required this.onCompleteMaintenance,
  });

  final Equipment equipment;
  final EquipmentData data;
  final VoidCallback onSendToMaintenance;
  final VoidCallback onCompleteMaintenance;

  @override
  Widget build(BuildContext context) {
    final bool isInMaintenance = equipment.status.isInMaintenance;
    return EquipmentCard(
      equipment: equipment,
      showMaintenanceDue: true,
      projectLabel: equipment.projectId == null
          ? null
          : data.projectsById[equipment.projectId]?.name,
      trailing: isInMaintenance
          ? AvahiButton(
              label: 'إنجاز الصيانة',
              size: AvahiButtonSize.small,
              icon: Icons.check_circle_outline,
              onPressed: onCompleteMaintenance,
            )
          : AvahiButton(
              label: 'إرسال للصيانة',
              size: AvahiButtonSize.small,
              variant: AvahiButtonVariant.secondary,
              icon: Icons.build_outlined,
              onPressed: onSendToMaintenance,
            ),
    );
  }
}
