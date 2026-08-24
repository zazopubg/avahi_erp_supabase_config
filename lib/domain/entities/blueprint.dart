import 'package:equatable/equatable.dart';

/// مخطط هندسي (Blueprint/Drawing) لمشروع إنشائي.
///
/// ⚠️ ملاحظة مخطط قاعدة بيانات: لا يوجد جدول Postgres مستقل باسم
/// `blueprints` ضمن هجرات Prompt 03 الحالية (`backend/supabase/migrations/`)؛
/// المخططات الهندسية تُخزَّن عملياً كصفوف في جدول `public.documents`
/// (انظر `010_create_documents.sql`) بقيمة `category = 'blueprint'`.
/// هذا الكيان مُشتق منطقياً بحقول [Document] الأساسية (تخزين، إصدار،
/// أرشفة) مضافاً إليها حقول خاصة بالمخططات الهندسية (رقم اللوحة،
/// التخصص، رمز المراجعة) شائعة في تطبيقات إدارة المخططات الإنشائية.
/// عند الوصول فعلياً لطبقة `data/` (Prompt 07) قد تحتاج هذه الحقول
/// الإضافية migration جديدة إن لزم تخزينها، أو تُشتق من [Document]
/// مباشرة دون عمود مستقل.
class Blueprint extends Equatable {
  const Blueprint({
    required this.id,
    required this.companyId,
    required this.projectId,
    required this.title,
    required this.storagePath,
    required this.version,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.sheetNumber,
    this.discipline,
    this.revisionCode,
    this.description,
    this.fileType,
    this.fileSizeBytes,
    this.previousVersionId,
    this.uploadedBy,
  });

  final String id;
  final String companyId;
  final String projectId;

  final String title;
  final String? description;

  /// رقم اللوحة/الصفحة ضمن مجموعة المخططات (مثال: `A-101`).
  final String? sheetNumber;

  /// التخصص الهندسي (معماري، إنشائي، كهرباء، ميكانيك...).
  final String? discipline;

  /// رمز/رقم المراجعة الحالي للمخطط (مثال: `Rev.C`).
  final String? revisionCode;

  final String storagePath;
  final String? fileType;
  final int? fileSizeBytes;

  final int version;
  final String? previousVersionId;

  final bool isArchived;
  final String? uploadedBy;

  final DateTime createdAt;
  final DateTime updatedAt;

  Blueprint copyWith({
    String? id,
    String? companyId,
    String? projectId,
    String? title,
    String? description,
    String? sheetNumber,
    String? discipline,
    String? revisionCode,
    String? storagePath,
    String? fileType,
    int? fileSizeBytes,
    int? version,
    String? previousVersionId,
    bool? isArchived,
    String? uploadedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Blueprint(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      sheetNumber: sheetNumber ?? this.sheetNumber,
      discipline: discipline ?? this.discipline,
      revisionCode: revisionCode ?? this.revisionCode,
      storagePath: storagePath ?? this.storagePath,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      version: version ?? this.version,
      previousVersionId: previousVersionId ?? this.previousVersionId,
      isArchived: isArchived ?? this.isArchived,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        companyId,
        projectId,
        title,
        description,
        sheetNumber,
        discipline,
        revisionCode,
        storagePath,
        fileType,
        fileSizeBytes,
        version,
        previousVersionId,
        isArchived,
        uploadedBy,
        createdAt,
        updatedAt,
      ];
}
