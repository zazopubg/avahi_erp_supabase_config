/// نوع الكيان المرتبط في علاقة polymorphic خفيفة، مطابق لعمود
/// `photos.related_entity_type` (انظر `009_create_photos.sql` →
/// `photos_related_entity_type_check`). يُستخدم في [SitePhoto] لربط
/// الصورة بالكيان الذي تخصّه (تقرير ميداني، عنصر ملاحظات، مهمة...).
///
/// ⚠️ تعداد إضافي غير مذكور صراحة في قائمة enums الخاصة بهذه الخطوة،
/// أُضيف لضمان أمان النوع (Type Safety) لحقل `relatedEntityType` في
/// [SitePhoto] بدل تركه نصاً حراً، بما يخدم متطلب "الحقول الكاملة
/// كما في مخطط قاعدة البيانات".
enum RelatedEntityType {
  fieldReport,
  punchItem,
  task,
  attendance,
  equipment,
  project;

  String get dbValue {
    switch (this) {
      case RelatedEntityType.fieldReport:
        return 'field_report';
      case RelatedEntityType.punchItem:
        return 'punch_item';
      case RelatedEntityType.task:
        return 'task';
      case RelatedEntityType.attendance:
        return 'attendance';
      case RelatedEntityType.equipment:
        return 'equipment';
      case RelatedEntityType.project:
        return 'project';
    }
  }

  static RelatedEntityType fromDbValue(String value) {
    return RelatedEntityType.values.firstWhere(
      (RelatedEntityType t) => t.dbValue == value,
      orElse: () => RelatedEntityType.task,
    );
  }

  /// 🆕 (Prompt 18) اسم عرض عربي مختصر — أول استخدام فعلي: قائمة
  /// اختيار الكيان المرتبط في `photo_attach_screen.dart`، وتبويبات
  /// الفلترة في `photo_gallery.dart` (سطح المكتب).
  String get displayNameAr {
    switch (this) {
      case RelatedEntityType.fieldReport:
        return 'تقرير ميداني';
      case RelatedEntityType.punchItem:
        return 'ملاحظة (Punch List)';
      case RelatedEntityType.task:
        return 'مهمة';
      case RelatedEntityType.attendance:
        return 'حضور';
      case RelatedEntityType.equipment:
        return 'معدة';
      case RelatedEntityType.project:
        return 'المشروع';
    }
  }
}
