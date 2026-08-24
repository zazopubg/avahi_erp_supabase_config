import 'package:equatable/equatable.dart';

/// مستند رسمي (عقد، تصريح...) تابع للشركة أو لمشروع محدد اختيارياً،
/// مع دعم أرشفة وإصدارات بسيطة عبر [previousVersionId]. مطابق لجدول
/// `public.documents` (انظر `010_create_documents.sql`).
class Document extends Equatable {
  const Document({
    required this.id,
    required this.companyId,
    required this.title,
    required this.storagePath,
    required this.version,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.projectId,
    this.description,
    this.category,
    this.fileType,
    this.fileSizeBytes,
    this.previousVersionId,
    this.uploadedBy,
  });

  final String id;
  final String companyId;
  final String? projectId;

  final String title;
  final String? description;
  final String? category;

  final String storagePath;
  final String? fileType;
  final int? fileSizeBytes;

  /// رقم الإصدار الحالي (يبدأ من 1).
  final int version;

  /// معرّف الإصدار السابق من نفس المستند، إن وُجد.
  final String? previousVersionId;

  final bool isArchived;
  final String? uploadedBy;

  final DateTime createdAt;
  final DateTime updatedAt;

  Document copyWith({
    String? id,
    String? companyId,
    String? projectId,
    String? title,
    String? description,
    String? category,
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
    return Document(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
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
        category,
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
