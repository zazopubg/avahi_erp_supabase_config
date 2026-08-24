import 'package:flutter/material.dart';

import '../../../../domain/enums/equipment_status.dart';
import '../../../../ui/widgets/common/status_badge.dart';

/// يحوّل [EquipmentStatus] إلى تسمية عربية وأيقونة ولون دلالي مناسب
/// — منطق مشترك بين [EquipmentStatusBadge] وبطاقة `equipment_card.dart`/
/// `equipment_details.dart`، بنفس نمط `documentFileVisuals` في
/// `documents/presentation/widgets/document_card.dart`.
(String, AvahiStatus, IconData) equipmentStatusVisuals(
  EquipmentStatus status,
) {
  switch (status) {
    case EquipmentStatus.available:
      return ('متاحة', AvahiStatus.success, Icons.check_circle_outline);
    case EquipmentStatus.inUse:
      return ('قيد الاستخدام', AvahiStatus.info, Icons.engineering_outlined);
    case EquipmentStatus.maintenance:
      return ('صيانة', AvahiStatus.warning, Icons.build_outlined);
    case EquipmentStatus.retired:
      return ('متقاعدة', AvahiStatus.neutral, Icons.block_outlined);
  }
}

/// شارة حالة معدة موحّدة — غلاف رفيع فوق [StatusBadge] العام بألوان
/// وتسميات [EquipmentStatus] الأربع، مستخدَمة عبر كل شاشات الميزة
/// (`equipment_card.dart`، `equipment_registry.dart`،
/// `equipment_details.dart`، `maintenance_schedule.dart`).
///
/// مكوّن عرض بحت — لا يحمل أي منطق تحديد الحالة الفعلي.
class EquipmentStatusBadge extends StatelessWidget {
  const EquipmentStatusBadge({required this.status, super.key, this.dense = false});

  final EquipmentStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (String label, AvahiStatus avahiStatus, IconData icon) =
        equipmentStatusVisuals(status);
    return StatusBadge(
      label: label,
      status: avahiStatus,
      icon: icon,
      dense: dense,
    );
  }
}
