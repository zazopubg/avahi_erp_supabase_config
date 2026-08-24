import 'package:equatable/equatable.dart';

import '../enums/equipment_status.dart';

/// معدة ميدانية تابعة للشركة، مع تتبّع حالتها، من يستخدمها حالياً،
/// وساعات التشغيل التراكمية، وتواريخ الصيانة. مطابقة لجدول
/// `public.equipment` (انظر `012_create_equipment.sql`). 🆕
class Equipment extends Equatable {
  const Equipment({
    required this.id,
    required this.companyId,
    required this.name,
    required this.type,
    required this.status,
    required this.usageHours,
    required this.createdAt,
    required this.updatedAt,
    this.projectId,
    this.nameAr,
    this.serialNumber,
    this.assignedTo,
    this.purchaseDate,
    this.lastMaintenanceDate,
    this.nextMaintenanceDue,
    this.notes,
    this.createdBy,
  });

  final String id;
  final String companyId;

  /// المشروع الذي توجد فيه المعدة حالياً، اختياري.
  final String? projectId;

  final String name;
  final String? nameAr;

  /// نوع/فئة المعدة (رافعة، خلاطة، مولّد...).
  final String type;

  final String? serialNumber;

  final EquipmentStatus status;

  /// معرّف المستخدم (`auth.users.id`) المُسندة إليه المعدة حالياً.
  final String? assignedTo;

  /// ساعات التشغيل التراكمية.
  final double usageHours;

  final DateTime? purchaseDate;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDue;

  final String? notes;
  final String? createdBy;

  final DateTime createdAt;
  final DateTime updatedAt;

  Equipment copyWith({
    String? id,
    String? companyId,
    String? projectId,
    String? name,
    String? nameAr,
    String? type,
    String? serialNumber,
    EquipmentStatus? status,
    String? assignedTo,
    double? usageHours,
    DateTime? purchaseDate,
    DateTime? lastMaintenanceDate,
    DateTime? nextMaintenanceDue,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Equipment(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      type: type ?? this.type,
      serialNumber: serialNumber ?? this.serialNumber,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      usageHours: usageHours ?? this.usageHours,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      nextMaintenanceDue: nextMaintenanceDue ?? this.nextMaintenanceDue,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        companyId,
        projectId,
        name,
        nameAr,
        type,
        serialNumber,
        status,
        assignedTo,
        usageHours,
        purchaseDate,
        lastMaintenanceDate,
        nextMaintenanceDue,
        notes,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
