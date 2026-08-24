import '../../domain/entities/app_notification.dart';
import '../../domain/enums/notification_type.dart';
import '../../domain/enums/related_entity_type.dart';
import 'dto_parsing_helpers.dart';

/// DTO مطابق لبنية جدول `public.notifications` (انظر
/// `013_create_notifications.sql` و`019_extend_notification_types.sql`). 🆕
class NotificationDto {
  const NotificationDto({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.title,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.body,
    this.relatedEntityType,
    this.relatedEntityId,
    this.readAt,
  });

  final String id;
  final String companyId;
  final String userId;
  final String title;
  final String? body;
  final String type;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      type: json['type'] as String,
      relatedEntityType: json['related_entity_type'] as String?,
      relatedEntityId: json['related_entity_id'] as String?,
      isRead: json['is_read'] as bool,
      readAt: parseNullableDateTime(json['read_at']),
      createdAt: parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'company_id': companyId,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'related_entity_type': relatedEntityType,
      'related_entity_id': relatedEntityId,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppNotification toEntity() {
    return AppNotification(
      id: id,
      companyId: companyId,
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.fromDbValue(type),
      relatedEntityType: relatedEntityType == null
          ? null
          : RelatedEntityType.fromDbValue(relatedEntityType!),
      relatedEntityId: relatedEntityId,
      isRead: isRead,
      readAt: readAt,
      createdAt: createdAt,
    );
  }

  factory NotificationDto.fromEntity(AppNotification entity) {
    return NotificationDto(
      id: entity.id,
      companyId: entity.companyId,
      userId: entity.userId,
      title: entity.title,
      body: entity.body,
      type: entity.type.dbValue,
      relatedEntityType: entity.relatedEntityType?.dbValue,
      relatedEntityId: entity.relatedEntityId,
      isRead: entity.isRead,
      readAt: entity.readAt,
      createdAt: entity.createdAt,
    );
  }
}
