import 'package:equatable/equatable.dart';

import '../enums/related_entity_type.dart';

/// صورة مرفقة بأي كيان في النظام عبر نمط polymorphic خفيف
/// ([relatedEntityType]/[relatedEntityId]). مطابقة لجدول
/// `public.photos` (انظر `009_create_photos.sql`).
class SitePhoto extends Equatable {
  const SitePhoto({
    required this.id,
    required this.companyId,
    required this.relatedEntityType,
    required this.relatedEntityId,
    required this.storagePath,
    required this.takenAt,
    required this.createdAt,
    this.projectId,
    this.thumbnailPath,
    this.caption,
    this.fileSizeBytes,
    this.latitude,
    this.longitude,
    this.uploadedBy,
  });

  final String id;
  final String companyId;
  final String? projectId;

  /// نوع الكيان المرتبط (تقرير ميداني، مهمة، عنصر ملاحظات...).
  final RelatedEntityType relatedEntityType;

  /// معرّف الكيان المرتبط.
  final String relatedEntityId;

  final String storagePath;
  final String? thumbnailPath;
  final String? caption;
  final int? fileSizeBytes;

  final DateTime takenAt;
  final double? latitude;
  final double? longitude;

  final String? uploadedBy;
  final DateTime createdAt;

  SitePhoto copyWith({
    String? id,
    String? companyId,
    String? projectId,
    RelatedEntityType? relatedEntityType,
    String? relatedEntityId,
    String? storagePath,
    String? thumbnailPath,
    String? caption,
    int? fileSizeBytes,
    DateTime? takenAt,
    double? latitude,
    double? longitude,
    String? uploadedBy,
    DateTime? createdAt,
  }) {
    return SitePhoto(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      projectId: projectId ?? this.projectId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      storagePath: storagePath ?? this.storagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      caption: caption ?? this.caption,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      takenAt: takenAt ?? this.takenAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        companyId,
        projectId,
        relatedEntityType,
        relatedEntityId,
        storagePath,
        thumbnailPath,
        caption,
        fileSizeBytes,
        takenAt,
        latitude,
        longitude,
        uploadedBy,
        createdAt,
      ];
}
