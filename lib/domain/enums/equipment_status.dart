/// حالة المعدة، مطابقة لعمود `equipment.status` (انظر
/// `012_create_equipment.sql` → `equipment_status_check`). 🆕
enum EquipmentStatus {
  /// متاحة وغير مُسندة لأحد حالياً.
  available,

  /// قيد الاستخدام حالياً من قبل [Equipment.assignedTo].
  inUse,

  /// خارج الخدمة مؤقتاً لأعمال صيانة.
  maintenance,

  /// أُخرجت نهائياً من الخدمة (لن تُسند بعد الآن).
  retired;

  String get dbValue {
    switch (this) {
      case EquipmentStatus.available:
        return 'available';
      case EquipmentStatus.inUse:
        return 'in_use';
      case EquipmentStatus.maintenance:
        return 'maintenance';
      case EquipmentStatus.retired:
        return 'retired';
    }
  }

  static EquipmentStatus fromDbValue(String value) {
    return EquipmentStatus.values.firstWhere(
      (EquipmentStatus s) => s.dbValue == value,
      orElse: () => EquipmentStatus.available,
    );
  }

  bool get isAvailable => this == EquipmentStatus.available;
  bool get isInUse => this == EquipmentStatus.inUse;
  bool get isInMaintenance => this == EquipmentStatus.maintenance;
  bool get isRetired => this == EquipmentStatus.retired;
}
