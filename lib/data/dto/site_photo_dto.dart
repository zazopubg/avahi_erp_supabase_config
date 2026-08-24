import '../../domain/entities/site_photo.dart';
import '../../domain/enums/related_entity_type.dart';
import 'dto_parsing_helpers.dart';

/// DTO مطابق لبنية جدول `public.photos` (انظر `009_create_photos.sql`)،
/// يقابل كيان [SitePhoto].
class SitePhotoDto {
  const SitePhotoDto({
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
  final String relatedEntityType;
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

  factory SitePhotoDto.fromJson(Map<String, dynamic> json) {
    return SitePhotoDto(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      projectId: json['project_id'] as String?,
      relatedEntityType: json['related_entity_type'] as String,
      relatedEntityId: json['related_entity_id'] as String,
      storagePath: json['storage_path'] as String,
      thumbnailPath: json['thumbnail_path'] as String?,
      caption: json['caption'] as String?,
      fileSizeBytes: parseNullableInt(json['file_size_bytes']),
      takenAt: parseDateTime(json['taken_at']),
      latitude: parseNullableDouble(json['latitude']),
      longitude: parseNullableDouble(json['longitude']),
      uploadedBy: json['uploaded_by'] as String?,
      createdAt: parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'company_id': companyId,
      'project_id': projectId,
      'related_entity_type': relatedEntityType,
      'related_entity_id': relatedEntityId,
      'storage_path': storagePath,
      'thumbnail_path': thumbnailPath,
      'caption': caption,
      'file_size_bytes': fileSizeBytes,
      'taken_at': takenAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// نسخة معدّة للإدراج (بدون `created_at` — يُملأ افتراضياً من
  /// الخادم عبر `default now()`).
  ///
  /// ⚠️ [id] **مُضمَّن هنا** خلافاً للتعليق الأصلي لهذه الدالة قبل
  /// Prompt 18 (كان يستبعد `id` معتمداً على `gen_random_uuid()`
  /// الافتراضي في `009_create_photos.sql`) — أُعيد هذا القرار عمداً
  /// الآن لأن [PhotoUploadProcessor] (`data/sync/outbox/`، Prompt 18)
  /// يحتاج معرّفاً متطابقاً بين صف `local_photo_queue` المحلي وصف
  /// `public.photos` السحابي الناتج عن رفعه (بالضبط كما وثّق تعليق
  /// `PhotoQueueTable.id` أصلاً منذ Prompt 08، لكن دون تفعيل فعلي حتى
  /// الآن) — يتيح ذلك إعادة محاولة رفع نفس الصف بأمان (Idempotent عبر
  /// `upsert` في `PhotoRepositoryImpl.uploadPhoto`) دون نسخ مكرّرة عند
  /// فشل شبكي بعد نجاح الإدراج فعلياً لكن قبل تأكيد الاستجابة للجهاز.
  /// لا يؤثر هذا على مسار `features/field_reports/` القائم أصلاً
  /// (`report_form_cubit.dart`) لأنه يُنشئ `id` محلياً بالفعل عبر
  /// `IdGenerator.v4()` قبل الاستدعاء — كان يُهدَر ضمناً سابقاً
  /// ويستبدله الخادم بمعرّف عشوائي آخر؛ الآن يُستخدَم فعلياً كما هو،
  /// وهو تصحيح متسق وليس تغييراً سلوكياً ملحوظاً من تلك الشاشة.
  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'id': id,
      'company_id': companyId,
      'project_id': projectId,
      'related_entity_type': relatedEntityType,
      'related_entity_id': relatedEntityId,
      'storage_path': storagePath,
      'thumbnail_path': thumbnailPath,
      'caption': caption,
      'file_size_bytes': fileSizeBytes,
      'taken_at': takenAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'uploaded_by': uploadedBy,
    };
  }

  SitePhoto toEntity() {
    return SitePhoto(
      id: id,
      companyId: companyId,
      projectId: projectId,
      relatedEntityType: RelatedEntityType.fromDbValue(relatedEntityType),
      relatedEntityId: relatedEntityId,
      storagePath: storagePath,
      thumbnailPath: thumbnailPath,
      caption: caption,
      fileSizeBytes: fileSizeBytes,
      takenAt: takenAt,
      latitude: latitude,
      longitude: longitude,
      uploadedBy: uploadedBy,
      createdAt: createdAt,
    );
  }

  factory SitePhotoDto.fromEntity(SitePhoto entity) {
    return SitePhotoDto(
      id: entity.id,
      companyId: entity.companyId,
      projectId: entity.projectId,
      relatedEntityType: entity.relatedEntityType.dbValue,
      relatedEntityId: entity.relatedEntityId,
      storagePath: entity.storagePath,
      thumbnailPath: entity.thumbnailPath,
      caption: entity.caption,
      fileSizeBytes: entity.fileSizeBytes,
      takenAt: entity.takenAt,
      latitude: entity.latitude,
      longitude: entity.longitude,
      uploadedBy: entity.uploadedBy,
      createdAt: entity.createdAt,
    );
  }
}
