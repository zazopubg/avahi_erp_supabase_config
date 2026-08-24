import '../../domain/entities/equipment.dart';
import '../../domain/enums/equipment_status.dart';
import 'dto_parsing_helpers.dart';

/// DTO مطابق لبنية جدول `public.equipment` (انظر
/// `012_create_equipment.sql`). 🆕
class EquipmentDto {
  const EquipmentDto({
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
  final String? projectId;
  final String name;
  final String? nameAr;
  final String type;
  final String? serialNumber;
  final String status;
  final String? assignedTo;
  final double usageHours;
  final DateTime? purchaseDate;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDue;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory EquipmentDto.fromJson(Map<String, dynamic> json) {
    return EquipmentDto(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      projectId: json['project_id'] as String?,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String?,
      type: json['type'] as String,
      serialNumber: json['serial_number'] as String?,
      status: json['status'] as String,
      assignedTo: json['assigned_to'] as String?,
      usageHours: parseDouble(json['usage_hours']),
      purchaseDate: parseNullableDateTime(json['purchase_date']),
      lastMaintenanceDate: parseNullableDateTime(json['last_maintenance_date']),
      nextMaintenanceDue: parseNullableDateTime(json['next_maintenance_due']),
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'company_id': companyId,
      'project_id': projectId,
      'name': name,
      'name_ar': nameAr,
      'type': type,
      'serial_number': serialNumber,
      'status': status,
      'assigned_to': assignedTo,
      'usage_hours': usageHours,
      'purchase_date': toNullableDateOnlyString(purchaseDate),
      'last_maintenance_date': toNullableDateOnlyString(lastMaintenanceDate),
      'next_maintenance_due': toNullableDateOnlyString(nextMaintenanceDue),
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// نسخة معدّة للإدراج (بدون `id`/`created_at`/`updated_at`).
  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'company_id': companyId,
      'project_id': projectId,
      'name': name,
      'name_ar': nameAr,
      'type': type,
      'serial_number': serialNumber,
      'status': status,
      'assigned_to': assignedTo,
      'usage_hours': usageHours,
      'purchase_date': toNullableDateOnlyString(purchaseDate),
      'last_maintenance_date': toNullableDateOnlyString(lastMaintenanceDate),
      'next_maintenance_due': toNullableDateOnlyString(nextMaintenanceDue),
      'notes': notes,
      'created_by': createdBy,
    };
  }

  Equipment toEntity() {
    return Equipment(
      id: id,
      companyId: companyId,
      projectId: projectId,
      name: name,
      nameAr: nameAr,
      type: type,
      serialNumber: serialNumber,
      status: EquipmentStatus.fromDbValue(status),
      assignedTo: assignedTo,
      usageHours: usageHours,
      purchaseDate: purchaseDate,
      lastMaintenanceDate: lastMaintenanceDate,
      nextMaintenanceDue: nextMaintenanceDue,
      notes: notes,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory EquipmentDto.fromEntity(Equipment entity) {
    return EquipmentDto(
      id: entity.id,
      companyId: entity.companyId,
      projectId: entity.projectId,
      name: entity.name,
      nameAr: entity.nameAr,
      type: entity.type,
      serialNumber: entity.serialNumber,
      status: entity.status.dbValue,
      assignedTo: entity.assignedTo,
      usageHours: entity.usageHours,
      purchaseDate: entity.purchaseDate,
      lastMaintenanceDate: entity.lastMaintenanceDate,
      nextMaintenanceDue: entity.nextMaintenanceDue,
      notes: entity.notes,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
