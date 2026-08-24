import '../../domain/entities/document.dart';
import 'dto_parsing_helpers.dart';

/// DTO مطابق لبنية جدول `public.documents` (انظر
/// `010_create_documents.sql`).
class DocumentDto {
  const DocumentDto({
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
  final int version;
  final String? previousVersionId;
  final bool isArchived;
  final String? uploadedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory DocumentDto.fromJson(Map<String, dynamic> json) {
    return DocumentDto(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      projectId: json['project_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      storagePath: json['storage_path'] as String,
      fileType: json['file_type'] as String?,
      fileSizeBytes: parseNullableInt(json['file_size_bytes']),
      version: parseNullableInt(json['version']) ?? 1,
      previousVersionId: json['previous_version_id'] as String?,
      isArchived: json['is_archived'] as bool,
      uploadedBy: json['uploaded_by'] as String?,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'company_id': companyId,
      'project_id': projectId,
      'title': title,
      'description': description,
      'category': category,
      'storage_path': storagePath,
      'file_type': fileType,
      'file_size_bytes': fileSizeBytes,
      'version': version,
      'previous_version_id': previousVersionId,
      'is_archived': isArchived,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// نسخة معدّة للإدراج (بدون `id`/`created_at`/`updated_at`).
  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'company_id': companyId,
      'project_id': projectId,
      'title': title,
      'description': description,
      'category': category,
      'storage_path': storagePath,
      'file_type': fileType,
      'file_size_bytes': fileSizeBytes,
      'version': version,
      'previous_version_id': previousVersionId,
      'is_archived': isArchived,
      'uploaded_by': uploadedBy,
    };
  }

  Document toEntity() {
    return Document(
      id: id,
      companyId: companyId,
      projectId: projectId,
      title: title,
      description: description,
      category: category,
      storagePath: storagePath,
      fileType: fileType,
      fileSizeBytes: fileSizeBytes,
      version: version,
      previousVersionId: previousVersionId,
      isArchived: isArchived,
      uploadedBy: uploadedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory DocumentDto.fromEntity(Document entity) {
    return DocumentDto(
      id: entity.id,
      companyId: entity.companyId,
      projectId: entity.projectId,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      storagePath: entity.storagePath,
      fileType: entity.fileType,
      fileSizeBytes: entity.fileSizeBytes,
      version: entity.version,
      previousVersionId: entity.previousVersionId,
      isArchived: entity.isArchived,
      uploadedBy: entity.uploadedBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
